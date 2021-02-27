% Assign case to referee
{assign(CID,RID)} :- case(CID, _, _, _, _, _), referee(RID, _, _, _, _).

% Common constraints
% Each insurance case is assigned to one single referee.
:- assign(CID, RID1), assign(CID, RID2), RID1!=RID2.

% We assume that if for a certain pair of rid and postc no pref is specified, then it is 0 by default.
:- not prefRegion(RID, POST, _), assign(CID,RID), case(CID, _, _, _, POST, _).

% We assume that if for a certain pair of rid and caset no pref is specified, then it is 0 by default.
:- not prefType(RID, CASE, _), assign(CID, RID), case(CID, CASE, _, _, _, _).

% Make sure all cases are assigned.
:- not assign(CID, _), case(CID, _, _, _, _, _).

% Hard constraints
% The maximum number of working minutes of a referee must not be exceeded by the actual workload, where the actual workload is the sum of the efforts of all cases assigned to this referee.
worktime(RID, TIME) :- referee(RID, _, _, _, _), TIME=#sum{EFFORT, CID: case(CID, _, EFFORT, _, _, _), assign(CID, RID)}.
:- worktime(RID, TIME), referee(RID, _, MAXTIME, _, _), MAXTIME<TIME.

% A case cannot be assigned to a referee who is not in charge of the region.
:- assign(CID, RID), case(CID, _, _, _, POST, _), referee(RID, _, _, _, _), prefRegion(RID, POST, 0).

% A case cannot be assigned to a referee who is not in charge of the type of the case.
:- assign(CID, RID), case(CID, CTYPE, _, _, _, _), referee(RID, _, _, _, _), prefType(RID, CTYPE, 0).

% The damage that exceeds the threshold can only be assigned to internal referees.
:- assign(CID, RID), case(CID, _, _, D1, _, _), referee(RID, e, _, _, _), externalMaxDamage(D2), D1>D2.

% Weak constraints
% Internal referees are preferred in order to minimize the costs of external ones.
% Scoring Schema
% A: The sum of all payments of cases assigned to external referees should be minimized. We let cA be the sum of all payments to external referees.
costA(COST) :- COST=#sum{PAYMENT, CID: case(CID, _, _, _, _, PAYMENT), assign(CID, RID),referee(RID, e, _, _, _)}.

% B: Let the overall payment orid of an external referee rid be the sum of her/his prev_payment and the payment s/he receives for newly assigned cases, and let avg be the average* overall payment over all external referees. To balance the overall payments of all external referees, for each referee rid, the divergence from the average is penalized with costs |avg - orid|. We let cB be the sum of all these costs.
overallcost(RID, COST) :- referee(RID, e, _, _, PPAY), TEMPCOST=#sum{PAYMENT, CID: case(CID, _, _, _, _, PAYMENT), assign(CID, RID)}, COST=TEMPCOST+PPAY. 
uniqueErefree(ECOUNT) :- ECOUNT=#count{RID: referee(RID, e, _, _, _)}, ECOUNT>0.
totalEcost(COST):- COST=COST1+COST2,COST1=#sum{PAYMENT,CID:case(CID, _, _, _, _, PAYMENT),referee(RID,e,_,_,_),assign(CID,RID)},COST2=#sum{PPAY,RID:referee(RID, e, _, _, PPAY)}.
avgcost(COST) :- uniqueErefree(ECOUNT), totalEcost(SCOST), COST=SCOST/ECOUNT, ECOUNT>0. 
costB(RID, DIV) :- overallcost(RID, OCOST), avgcost(COST), DIV=|COST-OCOST|.    


% C: Let the overall workload wrid of an (internal or external) referee rid be the sum of her/his prev_workload and the workload for newly assigned cases, and let avg be the average overall workload over all referees. To balance the workloads of all referees, for each referee rid, the divergence from the average is penalized with costs |avg - wrid|. We let cC be the sum of all these costs.
overalltime(RID, TIME) :- referee(RID, _, _, PREVLOAD, _), TEMPTIME=#sum{EFFORT, CID: case(CID, _, EFFORT, _, _, _), assign(CID, RID)}, TIME=TEMPTIME+PREVLOAD.
temptime(TIME):-TIME=#sum{EFFORT, CID: case(CID, _, EFFORT, _, _, _), assign(CID, RID)}.
uniquerefree(COUNT) :- COUNT=#count{RID: referee(RID, _, _, _, _)}.
prevtime(TIME):-TIME=#sum{EFFORT, RID: referee(RID, _, _, EFFORT, _) }.
avgtime(TIME) :- uniquerefree(COUNT), temptime(STIME), prevtime(PREVTIME),TIME=(STIME+PREVTIME)/COUNT.
costC(RID, DIV) :- overalltime(RID, OTIME), avgtime(TIME), DIV=|TIME-OTIME|.

% D: For a referee id rid, a case type caset, and an integer value pref in the range [0,3], a fact of form prefType(rid, caset, pref). encodes that rid should take a case with type caset with preference pref, where a higher value of pref denotes higher preference; the special case pref=0 means that rid is not allowed to take a case with type caset at all (hard constraint). For values pref > 0, taking a case causes costs (3 - pref). We let cD be the sum of all these costs.
costD(COST) :- COST=#sum{3-PREFCOST, CID: case(CID, CTYPE, _, _, _, _), prefType(RID, CTYPE, PREFCOST), assign(CID, RID),referee(RID, _, _, _, _)}.

% E: For a referee id rid, an integer postal code postc, and an integer value pref in the range [0,3], a fact of form prefRegion(rid, postc, pref). encodes that rid should take a case in region postc with preference pref, where a higher value of pref denotes higher preference; the special case pref=0 means that rid is not allowed to take a case in region c at all (hard constraint). For values pref > 0, taking a case causes costs (3 - pref). We let cE be the sum of all these costs.
costE(COST) :- COST=#sum{3-PREFCOST, CID: case(CID, _, _, _, POST, _), referee(RID, _, _, _, _), prefRegion(RID, POST, PREFCOST), assign(CID, RID)}.

% The overall costs to be minimized are given as follows:
% c = 16⋅cA + 7⋅cB + 9⋅cC + 34⋅cD + 34⋅cE
costADE(COST) :- costA(ACOST),costD(DCOST),costE(ECOST),COST=16*ACOST+34*DCOST+34*ECOST.

:~ costADE(COST). [COST]
:~ costB(RID,COST). [7*COST,RID]
:~ costC(RID,COST). [9*COST,RID]

#show assign/2.
