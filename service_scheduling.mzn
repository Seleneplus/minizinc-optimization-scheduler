%%%% Service and Maintenance scheduling
int: endtime;                   % latest time to be scheduled
set of int: TIME = 0..endtime;
enum SERVICE;                   % services to be scheduled
array[SERVICE] of TIME: start;  % start time of service
array[SERVICE] of TIME: end;    % end time of service
enum STYPE;
array[SERVICE] of STYPE: stype; % type of each service

enum TRUCK;                      % truck 
TRUCK: dtruck;                   % dummy truck
enum TTYPE = { SML, MED, LRG, DUMMY };  % truck type
array[TRUCK] of TTYPE: ttype;    % type of each truck
array[TRUCK] of int: prework;    % units of work since last major maintenance
constraint assert(forall(t in TRUCK)(ttype[t] = DUMMY <-> t = dtruck),"dummy type only for dtruck\n");
array[TTYPE] of int: maxsty;     % max service types for each truck type

enum MAINTYPE = { NO, SH, LG, MJ }; % NO means no maintenance
array[MAINTYPE] of int: maintdur; % duration of maintenance
array[MAINTYPE] of int: maxsep;   % max elapsed time since last maint of this type or higher
constraint assert(maintdur[NO] = 0 /\ maxsep[NO] = 0, "rules for empty maintenance\n");

int: minwork;                   % minimal percentage of time each truck that works is working
int: minservice;                % minimal percentage of services performed

int: majorwork;                 % amount of work allowed before major maintenance required


array[SERVICE] of var TRUCK: truck; % which truck takes each service: dtruck if none

int: maxmaint;
set of int: MAINT = 1..maxmaint;
array[TRUCK,MAINT] of var MAINTYPE: mt; % maintenance for each truck NO means not used.
array[TRUCK,MAINT] of var TIME: ms;     % maintenance start time for each truck

array[TIME] of var int: load_t;
var int: maintenance_load;
var int: service_time;


% Stage A: Prevent overlapping services on the same truck
  constraint
  forall( t in TRUCK diff {dtruck} )(
    forall(i, j in SERVICE where i < j )(
      (truck[i] = t /\ truck[j] = t) -> 
         (end[i] <= start[j] \/ end[j] <= start[i]) % services for the same truck cannot overlap
    )
  );  
       
 % stage B:Usage ratio constraints
 array[TRUCK] of var int: worktime = [ sum([end[s]-start[s]|s in SERVICE where truck[s] =t])| t in TRUCK]; % total working time for each truck
 int: total_services = card(SERVICE);% total number of services
 var int: performed_services=total_services-sum([bool2int(truck[s]=dtruck)|s in SERVICE]);
 constraint forall(t in TRUCK diff{dtruck})(worktime[t]>0  %each working truck must have a minimum work percentage
 ->worktime[t]*100>=minwork*endtime);
 constraint performed_services*100>= minservice*total_services; % Total performed services must meet minimum service percentage
 

 %stage c:service type diversity
 constraint(forall(t in TRUCK diff{dtruck})(
 let{
 var set of STYPE:types_done = {stype[s]|s in SERVICE where truck[s]=t}
 } in 
 card(types_done)<= maxsty[ttype[t]]
 ));
 
 %stage D maintenance
 %calculate maintenance end times for each truck
 array[TRUCK, MAINT] of var TIME:me =
   array2d(TRUCK,MAINT,
   [if mt[t,m]== NO then 0 else ms[t,m]+maintdur [mt[t,m]] endif
   | t in TRUCK, m in MAINT]);
   
% Dummy truck has no maintenance
constraint forall(m in MAINT)(
  mt[dtruck, m] == NO  
); 
   
% all no maintenance must be in the end of the maintenance sequence for each truck
constraint forall(t in TRUCK)(
  forall(m in 1..maxmaint-1)(  
    (mt[t,m]==NO)->(mt[t,m+1]==NO)
    )
    );
    
 % if no maintenance then start time is 0  
constraint forall(t in TRUCK)(
 forall(m in 1..maxmaint)(
 mt[t,m]=NO->ms[t,m]==0));
    
%maintenance start times must be ordered and maintenances cannot overlap
constraint forall(t in TRUCK)(
  forall(m in 1..maxmaint-1)(
    (mt[t,m] != NO /\mt[t,m+1] !=NO)->(me[t,m]<= ms[t,m+1])
    )
    );
    
%no maintenance no services
constraint forall(t in TRUCK)(
  (worktime[t]==0)->(forall(m in MAINT)(mt[t,m]==NO))
  );
  
%maintenance periods must not overlap with service periods on the same truck
constraint forall(t in TRUCK diff{dtruck}, s in SERVICE, m in MAINT)(
    (truck[s]==t/\mt[t,m]!=NO)->
    (end[s]<=ms[t,m]\/me[t,m]<=start[s]));
    
    
    
%First SH/LG/MJ maintenance must start within maxsep[SH]    
constraint forall(t in TRUCK diff{dtruck}) (
    worktime[t] > 0 ->
        exists(m in MAINT)(
            mt[t, m] in {SH, LG, MJ} /\
            ms[t, m] <= maxsep[SH]
        )
);

% First LG/MJ maintenance must start within maxsep[LG]
constraint forall(t in TRUCK diff{dtruck}) (
    worktime[t] > 0 ->
        exists(m in MAINT)(
            mt[t, m] in {LG, MJ} /\
            ms[t, m] <= maxsep[LG]
        )
);
% After each SH/LG/MJ maintenance, next SH/LG/MJ must be within maxsep[SH]
constraint forall(t in TRUCK diff{dtruck}, m1 in MAINT) (
    (mt[t, m1] in {SH, LG, MJ} /\ me[t, m1]+ maxsep[SH] < endtime) ->
        exists(m2 in MAINT) (
            m2 != m1 /\
            mt[t, m2] in {SH, LG, MJ} /\
            ms[t, m2] >= ms[t, m1] + maintdur[mt[t, m1]] /\
            ms[t, m2] <= me[t, m1] + maxsep[SH]
        )
);
%After each LG/MJ maintenance, next LG/MJ must be within maxsep[LG]
constraint forall(t in TRUCK diff{dtruck}, m1 in MAINT) (
    (mt[t, m1] in {LG, MJ} /\ me[t, m1] + maxsep[LG] < endtime) ->
        exists(m2 in MAINT) (
            m2 != m1 /\
            mt[t, m2] in {LG, MJ} /\
            ms[t, m2] >= ms[t, m1] + maintdur[mt[t, m1]] /\
            ms[t, m2] <= me[t, m1] + maxsep[LG]
        )
);  

%check wether the last maintenance cover the endtime
constraint forall(t in TRUCK diff{dtruck})(
worktime[t]>0->
let{
var MAINT:last_m=max([m|m in MAINT where mt[t,m]!=NO])}in
me[t,last_m]+maxsep[SH]>=endtime);   


%stageE:optimization objectives
%calculate maintenance load at each time point
constraint forall(t in TIME)(
  load_t[t]=sum([
    bool2int(ms[tr,m]<=t/\t<ms[tr,m]+maintdur[mt[tr,m]])
    | tr in TRUCK, m in MAINT where mt[tr,m]!=NO]));
    
%total maintenance load is sum of squares of simultaneous maintenance tasks
constraint maintenance_load=sum([load_t[t]*load_t[t]|t in TIME]);

%total service duration performed(excluding dummy truck)
constraint service_time=sum([end[s]-start[s]|s in SERVICE where truck[s]!=dtruck]);

%define objective:first minimize maintenance load, then maximize service time
var int:obj=maintenance_load*1000+(endtime*card(SERVICE)-service_time);

solve minimize obj;



