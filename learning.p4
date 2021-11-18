/*
SELF — Self-contained User Data Preserving Framework
MAC-Learning P4 Switch
Copyright (C) 2021 by Thomas Dreibholz

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

Contact: dreibh@simula.no
*/

/*
 * With digest part based on:
 * https://github.com/nsg-ethz/p4-learning/blob/master/exercises/04-L2_Learning/thrift/solution/p4src/l2_learning_digest.p4
 */

#include <core.p4>
#include <v1model.p4>


/* ####################################################################### */
/* #### Headers                                                       #### */
/* ####################################################################### */

typedef bit<48> macAddr_t;

struct mac_to_port_mapping_t {
   bit<48> address;
   bit<9>  port;
}

struct metadata {
   mac_to_port_mapping_t mac_to_port_mapping;
}

header ethernet_t {
   macAddr_t dstAddr;
   macAddr_t srcAddr;
   bit<16>   etherType;
}

struct headers {
   ethernet_t ethernet;
}


/* ####################################################################### */
/* #### Parser                                                        #### */
/* ####################################################################### */

parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata)
{
   state start {
      transition parse_ethernet;
   }

   state parse_ethernet {
      packet.extract(hdr.ethernet);
      transition accept;
   }
}


/* ####################################################################### */
/* #### Checksum Verification                                         #### */
/* ####################################################################### */

control MyVerifyChecksum(inout headers hdr, inout metadata meta) {
   apply {
      /* nothing to do here! */
   }
}


/* ####################################################################### */
/* #### Ingress                                                       #### */
/* ####################################################################### */

control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata)
{
   /* ====== Table for learning the Source Address to Port mapping ======= */
   action mac_to_port_mapping_mac_to_port_mapping() {
      meta.mac_to_port_mapping.address = hdr.ethernet.srcAddr;
      meta.mac_to_port_mapping.port    = standard_metadata.ingress_port;
      /* Provide information to the controller */
      digest<mac_to_port_mapping_t>(1, meta.mac_to_port_mapping);
   }

   table smac {
      key = {
         hdr.ethernet.srcAddr: exact;
      }
      actions = {
         mac_to_port_mapping_mac_to_port_mapping;
         NoAction;
      }
      size = 1024;
      default_action = mac_to_port_mapping_mac_to_port_mapping;
   }

   /* ====== Table for Forwarding by Destination Address ================ */
   action forward(bit<9> egress_port) {
      standard_metadata.egress_spec = egress_port;
   }

   table dmac {
      key = {
         hdr.ethernet.dstAddr: exact;
      }
      actions = {
         forward;
         NoAction;
      }
      size = 1024;
      default_action = NoAction;
   }

   /* ====== Table for Broadcast/Multicast handling ===================== */
   action set_mcast_grp(bit<16> mcast_grp) {
      standard_metadata.mcast_grp = mcast_grp;
   }

   table broadcast {
      key = {
         standard_metadata.ingress_port: exact;
      }
      actions = {
         set_mcast_grp;
         NoAction;
      }
      size = 1024;
      default_action = NoAction;
   }

   apply {
      smac.apply();
      if (!dmac.apply().hit) {
         /* Unknown device -> broadcast is necessary! */
         broadcast.apply();
      }
   }
}


/* ####################################################################### */
/* #### Egress                                                        #### */
/* ####################################################################### */

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata)
{
   apply {
      /* nothing to do here! */
   }
}


/* ####################################################################### */
/* #### Checksum Computation                                          #### */
/* ####################################################################### */

control MyComputeChecksum(inout headers  hdr, inout metadata meta)
{
   apply {
      /* nothing to do here! */
   }
}


/* ####################################################################### */
/* #### Deparser                                                      #### */
/* ####################################################################### */

control MyDeparser(packet_out packet, in headers hdr)
{
   apply {
      packet.emit(hdr.ethernet);
   }
}


/* ####################################################################### */
/* #### Switch                                                        #### */
/* ####################################################################### */

V1Switch(
   MyParser(),
   MyVerifyChecksum(),
   MyIngress(),
   MyEgress(),
   MyComputeChecksum(),
   MyDeparser()
) main;
