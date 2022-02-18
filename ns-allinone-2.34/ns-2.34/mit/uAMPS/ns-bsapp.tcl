############################################################################
#
# This code was developed as part of the MIT uAMPS project. (June, 2000)
#
############################################################################


# Message Constants
set MAC_BROADCAST 0xffffffff
set LINK_BROADCAST 0xffffffff
set DATA 1
set INFO 0
set BS_CH_INFO 0


############################################################################
#
# Base Station Application
#
############################################################################

Class Application/BSApp -superclass Application


Application/BSApp instproc init args {

  $self instvar rng_ total_ now_ code_ 

  set rng_ [new RNG]
  $rng_ seed 0
  set total_ 0
  set now_ 0
  set code_ 0

  $self next $args

}

Application/BSApp instproc start {} {

  global opt ns_
  $self instvar code_ now_ data_ 

  set now_ [$ns_ now]
  set code_ $opt(bsCode)
  #puts "the base station code is:$code_"
  [$self mac] set code_ $code_
  [$self mac] set node_num_ [$self nodeID]

  # Keep track of the data received from each node.  Data may be received
  # either directly or as part of an aggregate signal.
  for {set i 0} {$i < $opt(nn_)} {incr i} {
      set data_($i) 0
    #$self recv
  }
  #source /home/chiranjib/ns-allinone-2.34/ns-2.34/mit/uAMPS/ns-leach-c.tcl 
   
  # If running leach-c or stat-clus, BS sets up clusters.
  # Use a C++ routine to determine optimal clusters.
  # Must pass agent the appropriate parameters for cluster formation.
  if {$opt(rcapp) == "LEACH/LEACH-C" ||$opt(rcapp) == "LEACH-C/StatClustering"} {
      [$self agent] transfer_info [expr $opt(nn) - 1] $opt(num_clusters) $opt(bs_setup_iters) $opt(bs_setup_max_eps)
      $ns_ at [expr $now_ + $opt(finish_adv)] "$self BSsetup"

  }

}


############################################################################
#
# Helper Functions
#
############################################################################

Application/BSApp instproc node {} {
  return [[$self agent] set node_]
}

Application/BSApp instproc nodeID {} {
  return [[$self node] id]
}

Application/BSApp instproc mac {} {
  return [[$self node] set mac_(0)]
}

Application/BSApp instproc getData {id} {
  $self instvar data_
  #return $data_($id)
  #puts "data_id:$data_($id)"
 return $data_($id)
}
Application/BSApp instproc getX {} {
  return [[$self node] set X_]
}

Application/BSApp instproc getY {} {
  return [[$self node] set Y_]
}

Application/BSApp instproc getER {} {
  set er [[$self node] getER]
  return $er
}

############################################################################
#
# Receiving Functions   Link_dst = 7, Type=1 data_size=52	Meta = 4,source = 41
#
############################################################################

Application/BSApp instproc recv {args} {

  global INFO DATA

  # If recv_code is 1, have just received centralized
  # cluster formation information.
  # If recv_code is 0, have just received a packet.
  set recv_code [[$self agent] set recv_code_] 
  puts "recv_code :$recv_code"
  if {$recv_code == 1} {
    $self recvClusterInfo $args
  } else {
    set msg_type [[$self agent] set packetMsg_]
    #puts "msg_type::$msg_type"
    #set chID [[$self agent] set source_]
    set chID [lindex $args 0]
    set sender [lindex $args 1]
    set data_size [lindex $args 2]
    set msg [lrange $args 3 end]
    set nodeID [$self nodeID]
    #puts "Message:$msg"
    #puts "data:$DATA"
    #puts "Info:$INFO"
    if {$msg_type == $DATA} {
     $self recvDATA $sender $msg
	#puts "executing rdata"        
             } elseif {$msg_type == $INFO} {
	$self recvINFO $sender $msg
	puts "executing rinfo"      
    }
  }
}

Application/BSApp instproc recvINFO {sender msg} {
  global opt
#source /home/chiranjib/ns-allinone-2.34/ns-2.34/mit/uAMPS/ns-leach.tcl
  $self instvar total_
   #puts "executing RecvInfo function"
   if {$total_ == 0} {
    for {set i 0} {$i < [expr $opt(nn) - 1]} {incr i} {
        [$self agent] append_info $i 0 0 0
    }
  }

  set X [lindex $msg 0]
  set Y [lindex $msg 1]
  set E [lindex $msg 2]
  incr total_
  puts "BS received info: ($X $Y $E) from Node $sender" 
  puts "BS received: $total_ "
  [$self agent] append_info $sender $X $Y $E 

}


Application/BSApp instproc recvClusterInfo args {

    global MAC_BROADCAST LINK_BROADCAST BS_CH_INFO opt
    $self instvar code_ now_ ch_index_

    set ch_index $args
    set mac_dst [expr 0xffffffff]
    set link_dst [expr 0xffffffff]
    set msg [list [list $ch_index]]
    set datasize [expr 4 * [llength [join $ch_index]]]

    # Broadcast cluster information to sensor nodes.
    $self send $mac_dst $link_dst $BS_CH_INFO $msg $datasize 10 $code_
    puts "baseStation send $mac_dst $link_dst $BS_CH_INFO msg:$msg $datasize 10 $code_"
    set now_ [expr $now_ + $opt(ch_change)]
    set ch_index_ [join $ch_index]
    puts "ch_index:$ch_index_"
}

 Application/BSApp instproc recvDATA {sender msg} {
  global ns_ opt node_
  $self instvar data_  
   #puts "executing this Rdata function";
  # Keep track of how much data is received from each node.
  # Data may be sent directly or via an aggregate signal.
  puts "BS Received data $msg from $sender at time [$ns_ now]";
  set nodes_data "";
  set actual_nodes_data 0;
  #puts "msgin:$msg";
  set nodes_data 0
   #puts "nodes_data:$nodes_data";
    foreach i $nodes_data {
      if {[[$node_($i) set rca_app_] set alive_] == 1} {
        incr data_($i)
        lappend actual_nodes_data $i
             }
    }
    #puts "This represents data from nodes: $actual_nodes_data"
}


############################################################################
#
# Sending Functions
#
############################################################################

Application/BSApp instproc send {mac_dst link_dst type msg
                                      data_size dist code} {
    [$self agent] set packetMsg_ $type
    [$self agent] set dst_port_ $mac_dst
    [$self agent] set dst_port_ $link_dst
    [$self agent] sendmsg $data_size $msg $mac_dst $link_dst $dist $code
}

Application/BSApp instproc BSsetup {} {
  global ns_ opt
  $self instvar total_
  
  #set total_ [expr 4]
  # Use a C++ routine to determine optimal clusters.
  if {$total_ > $opt(num_clusters)} {
   puts "hello"
    [$self agent] transfer_info [expr $opt(nn) - 1] \
                      $opt(num_clusters) \
                      $opt(bs_setup_iters) \
                      $opt(bs_setup_max_eps)
    [$self agent] BSsetup
  } else {
    # If there are too few nodes to form clusters, end simulation.
    puts "Only received info from $total_ nodes."
    puts "There are currently $opt(nn_) alive ==> \
          $opt(num_clusters) cluster-heads needed."
    "sens_finish"
    #$ns_ at [expr [$ns_ now] + $opt(ch_change)] "$self BSsetup"
  }
  set total_ 0
  # Only LEACH-C performs set-up once every round. 
  if {$opt(rcapp) == "LEACH/LEACH-C"} {
    $ns_ at [expr [$ns_ now] + $opt(ch_change)] "$self BSsetup"
  }

}

