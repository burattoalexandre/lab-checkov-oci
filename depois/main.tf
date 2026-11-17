# Laboratorio SBC na OCI - versao corrigida

resource "oci_core_vcn" "vcn_sbc" {
  compartment_id = var.compartment_id
  cidr_blocks    = ["10.20.0.0/16"]
  display_name   = "vcn-sbc"
}

resource "oci_core_security_list" "sl_sbc" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn_sbc.id
  display_name   = "sl-sbc"

  ingress_security_rules {
    protocol = "6" # TCP
    source   = "10.30.0.0/16" # SSH so a partir do backbone
    tcp_options {
      min = 22
      max = 22
    }
  }

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }
}

resource "oci_core_network_security_group" "nsg_sbc" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn_sbc.id
  display_name   = "nsg-sbc"
}

resource "oci_core_network_security_group_security_rule" "sip_backbone" {
  #checkov:skip=CKV_OCI_21:SIP depende de regra stateful para o retorno das respostas
  network_security_group_id = oci_core_network_security_group.nsg_sbc.id
  direction                 = "INGRESS"
  protocol                  = "17" # UDP
  source                    = "10.30.0.0/16" # somente o backbone
  source_type               = "CIDR_BLOCK"
  udp_options {
    destination_port_range {
      min = 5060
      max = 5060
    }
  }
}

resource "oci_core_instance" "sbc_sim" {
  availability_domain = var.ad
  compartment_id      = var.compartment_id
  shape               = "VM.Standard.E4.Flex"
  display_name        = "sbc-sim"

  launch_options {
    is_pv_encryption_in_transit_enabled = true
  }

  instance_options {
    are_legacy_imds_endpoints_disabled = true
  }

  shape_config {
    ocpus         = 1
    memory_in_gbs = 8
  }

  create_vnic_details {
    subnet_id = var.subnet_id
    nsg_ids   = [oci_core_network_security_group.nsg_sbc.id]
  }

  source_details {
    source_type = "image"
    source_id   = var.image_id
  }
}

resource "oci_objectstorage_bucket" "pcaps" {
  compartment_id = var.compartment_id
  namespace      = var.namespace
  name           = "pcaps-voip"
  access_type           = "NoPublicAccess"
  versioning            = "Enabled"
  object_events_enabled = true
  kms_key_id            = var.kms_key_id
}
