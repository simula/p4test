/*
SELF — Self-contained User Data Preserving Framework
Simple P4 forwarding switch with only 2 ports
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

#include <core.p4>
#include <v1model.p4>


/* ####################################################################### */
/* #### Headers                                                       #### */
/* ####################################################################### */

typedef bit<48> macAddr_t;

struct metadata {
   /* empty */
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
   action drop() {
      mark_to_drop(standard_metadata);
   }
    
   table drop_packet {
      actions = {
         drop;
      }
      default_action = drop();
   }

   apply {
      if(standard_metadata.ingress_port <= 1) {
         standard_metadata.egress_spec = 1 - standard_metadata.ingress_port;
      } else {
         drop_packet.apply();
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
