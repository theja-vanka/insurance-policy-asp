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
worktime(RID, TIME) :- referee(RID, _, _, _, _), TIME = #sum{EFFORT : case(CID, _, EFFORT, _, _, _), assign(CID, RID)}.
:- worktime(RID, TIME), referee(RID, _, MAXTIME, _, _), MAXTIME<TIME.

% A case cannot be assigned to a referee who is not in charge of the region.
:- assign(CID, RID), case(CID, _, _, _, POST, _), referee(RID, _, _, _, _), prefRegion(RID, POST, 0).

% A case cannot be assigned to a referee who is not in charge of the type of the case.
:- assign(CID, RID), case(CID, CASE, _, _, _, _), referee(RID, _, _, _, _), prefType(RID, CASE, 0).

% The damage that exceeds the threshold can only be assigned to internal referees.
:- assign(CID, RID), case(CID, _, _, D1, _, _), referee(RID, e, _, _, _), externalMaxDamage(D2), D1>D2.

% #show assign/2.

