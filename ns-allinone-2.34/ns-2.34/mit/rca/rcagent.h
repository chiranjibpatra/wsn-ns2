/*************************************************************************
 *
 * This code was developed as part of the MIT SPIN project. (June, 1999)
 *
 *************************************************************************/


#ifndef ns_rca_h
#define ns_rca_h

#include "math.h"
#include "object.h"
#include "agent.h"
#include "trace.h"
#include "packet.h"
#include "priqueue.h"
#include "mac.h"
#include "random.h"

#include "agent.h"
#include "app.h"

#define SAMPLERATE 8000
#define ADV 0
#define REQ 2
#define DATA 1
#define RESEND 3

class RCAgent : public Agent {
public:
  RCAgent();
  ~RCAgent();
  void sendmsg(int data_size, const char* meta_data, int destination, 
               int sendto, double dist_to_dest, int code);
  void recv(Packet*, Handler*);
//  void log(const char *msg);
  int command(int argc, const char*const* argv);

protected:
  int packetMsg_;
  int packetSize_;
  int distEst_;
  int source_;

private:

  NsObject *ll;            // our link layer object 
  Mac *mac;    // our MAC layer object

  Trace *log_target;  // log target
};

#endif



