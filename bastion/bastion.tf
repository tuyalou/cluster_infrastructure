provider "google" {
  credentials = "${file("./fuchicorp-service-account.json")}"
  project     = "${var.google_project_id}"
  zone        = "${var.zone}"
}



resource "google_compute_firewall" "default" {
  name    = "bastion-network-firewall"
  network = "${google_compute_instance.vm_instance.network_interface.0.network}"

  allow { protocol = "icmp" }
  allow { protocol = "tcp" ports = ["80", "443"] }

  source_ranges = ["0.0.0.0/0"]
  source_tags = ["bastion-firewall"]
}



resource "google_compute_instance" "vm_instance" {
  name         = "bastion-${replace(var.google_domain_name, ".", "-")}"
  machine_type = "${var.machine_type}"

  tags = ["bastion-firewall"]

  boot_disk {
    initialize_params {
      size = "${var.instance_disk_zie}" 
      image = "${var.ami_id}"
    }

  }

  network_interface {
    network       = "default"
    # network       = "${google_compute_network.vpc_network.name}"
    access_config = {}
  }
  
  metadata {
    sshKeys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
  }

  metadata_startup_script = <<EOF
  echo "30 * * * * source /root/.bashrc && cd /common_scripts/bastion-scripts/ && python3 sync-users.py" >> /sync-crontab
  echo "0 2 * * */2,4,6 /usr/bin/find /home -iname '.terraform' -exec rm -rf {} \;" >> /sync-crontab
  crontab /sync-crontab
EOF
}

resource "null_resource" "local_generate_kube_config" {
  depends_on = ["google_compute_instance.vm_instance"]
  provisioner "local-exec" {
    command = <<EOF
    #!/bin/bash
    until ping -c1 ${google_compute_instance.vm_instance.network_interface.0.access_config.0.nat_ip} >/dev/null 2>&1; do echo "Tring to connect bastion host '${google_compute_instance.vm_instance.network_interface.0.access_config.0.nat_ip}' "; sleep 2; done
    wget https://raw.githubusercontent.com/fuchicorp/common_scripts/master/set-environments/kubernetes/set-kube-config.sh 
    ENDPOINT=$(kubectl get endpoints kubernetes | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')
    bash set-kube-config.sh $ENDPOINT
    ssh ${var.gce_ssh_user}@${google_compute_instance.vm_instance.network_interface.0.access_config.0.nat_ip} sudo mkdir /fuchicorp | echo 'Folder exist'
    scp -r  "admin_config"   ${var.gce_ssh_user}@${google_compute_instance.vm_instance.network_interface.0.access_config.0.nat_ip}:~/
    scp -r  "view_config"   ${var.gce_ssh_user}@${google_compute_instance.vm_instance.network_interface.0.access_config.0.nat_ip}:~/
    ssh ${var.gce_ssh_user}@${google_compute_instance.vm_instance.network_interface.0.access_config.0.nat_ip} sudo mv -f ~/*config /fuchicorp/
    rm -rf set-kube-config*
EOF
  }
}

resource "google_dns_record_set" "fuchicorp" {
  depends_on = ["google_compute_instance.vm_instance"]
  managed_zone = "fuchicorp"
  name         = "bastion.${var.google_domain_name}."
  type         = "A"
  ttl          = 300
  rrdatas      = ["${google_compute_instance.vm_instance.network_interface.0.access_config.0.nat_ip}"]
}
