SET SEARCH_PATH TO parlgov;
drop table if exists q7 cascade;

-- You must not change this table definition.

DROP TABLE IF EXISTS q7 CASCADE;
CREATE TABLE q7(
partyId INT, 
partyFamily VARCHAR(50) 
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
DROP VIEW IF EXISTS intermediate_step CASCADE;

-- Define views for your intermediate steps here.
create view election_winners as
select  election.id as election_id , cabinet_party.party_id
from election join cabinet
on election.id = cabinet.election_id
join cabinet_party
on cabinet.id = cabinet_party.cabinet_id
where cabinet_party.pm = true;


CREATE VIEW all_election_comb as 
SELECT country.name as country, election_id, alliance_id,election_result.party_id,election_result.party_id as partyId,election_result.id as res_id,votes,election.previous_parliament_election_id as prev_pid,election.previous_ep_election_id as prev_epid
,election.e_date,election.e_type
FROM election,election_result,country,party
WHERE election.id=election_result.election_id and election.country_id=country.id and election_result.party_id = party.id;


--Combioning election result with country name,party name
CREATE VIEW election_comb as 
SELECT country.name as country, election_id, alliance_id,election_result.party_id,election_result.party_id as partyId,election_result.id as res_id,votes,election.previous_parliament_election_id as prev_pid,election.previous_ep_election_id as prev_epid
,election.e_date,election.e_type
FROM election,election_result,country,party
WHERE election.id=election_result.election_id and election.country_id=country.id and election_result.party_id = party.id and election.e_type='Parliamentary election';




CREATE VIEW ep_election_no_prev_date AS
SELECT election_id,prev_pid,prev_epid,e_date,country
FROM all_election_comb
WHERE e_type='European Parliament';

CREATE VIEW ep_election_not_first AS
SELECT e1.election_id,e1.prev_epid,e1.prev_pid,e1.e_date, e2.e_date as prev_epdate,e1.country as ep_country, e2.country as prev_ep_country
FROM ep_election_no_prev_date e1, ep_election_no_prev_date e2
WHERE e1.prev_epid IS NOT NULL AND e1.prev_epid = e2.election_id;

CREATE VIEW ep_election_first AS
SELECT election_id,prev_epid,prev_pid,e_date, NULL as prev_epdate,country as ep_country,NULL as prev_ep_country
FROM ep_election_no_prev_date 
WHERE  prev_epid IS NULL;

CREATE VIEW ep_election AS SELECT * FROM ep_election_first UNION SELECT * FROM ep_election_not_first;

--SELECT * FROM ep_election;
CREATE VIEW all_winners AS
SELECT * FROM election_comb WHERE (election_id,party_id) IN (SELECT * FROM election_winners);

--Winners without allowance
CREATE VIEW winners_na AS
SELECT * FROM all_winners WHERE alliance_id is NULL AND res_id NOT IN (SELECT alliance_id FROM election_comb WHERE alliance_id IS NOT NULL);

--Winners from election winners comb with one representative from alliance
CREATE VIEW winners_a_one AS
SELECT * FROM all_winners except SELECT * FROM winners_na;

--election winners with alliance
CREATE VIEW winners_a AS
SELECT * FROM election_comb
WHERE   (alliance_id IS NULL AND (election_id,party_id) NOT IN (SELECT election_id,party_id FROM winners_na) 
			AND (election_id,party_id) IN (SELECT election_id,party_id FROM all_winners) 
		)
		OR
		( alliance_id IS NOT NULL AND (alliance_id,election_id) in (SELECT res_id,election_id FROM all_winners)

		);

CREATE VIEW winners_comb AS
SELECT * FROM winners_a UNION SELECT * FROM winners_na;

CREATE VIEW atleast_one_winner AS
SELECT *
FROM winners_comb w
WHERE EXISTS(SELECT * from ep_election where ep_election.ep_country=w.country and w.e_date < ep_election.e_date);


CREATE VIEW not_strong_parties AS
SELECT w.party_id,w.country
FROM atleast_one_winner w, ep_election e
WHERE 
	e.prev_epid IS NOT NULL AND 
	NOT EXISTS( SELECT * from winners_comb w2 where w.country = w2.country and w.election_id=w2.election_id and w.party_id=w2.party_id
				and w2.e_date>=e.prev_epdate and  w2.e_date <e.e_date)
	AND w.country = e.ep_country;

--SELECT * FROM not_strong_parties;
--SELECT * from atleast_one_winner;
CREATE VIEW answer1 AS 
(SELECT party_id from atleast_one_winner) except (select party_id from not_strong_parties);

CREATE VIEW answer2 as SELECT * FROM
(SELECT party_id FROM answer1)A NATURAL RIGHT JOIN (SELECT * FROM party_family)B;
CREATE VIEW answer as 
SELECT party_id as partyID, family as partyFamily FROM answer2;
insert into q7 select * from answer;
--elect * from answer;
/*
SELECT * FROM ep_election;



CREATE VIEW atleast_one_winner AS
SELECT w.partyId,w.election_id,w.e_date,w.prev_epid,w.prev_pid,w.res_id,w.country
FROM winners_comb w, ep_election ep
WHERE ep.prev_pid IS NOT NULL AND w.election_id = ep.prev_pid;

--SELECT * FROM atleast_one_winner order by country,election_id;

CREATE VIEW not_strong_parties AS
SELECT a.partyId,a.election_id,a.e_date,a.prev_epid,a.prev_pid,a.res_id,a.country
FROM atleast_one_winner a , ep_election e
WHERE e.prev_pid IS NOT NULL AND e.prev_pid = a.election_id and (a.election_id,a.partyId) not in (select election_id,party_id from winners_comb	);


CREATE VIEW strong_parties AS
SELECT * FROM atleast_one_winner except SELECT * FROM not_strong_parties;

CREATE VIEW answer AS
SELECT DISTINCT partyID FROM strong_parties;



SELECT * FROM not_strong_parties order by country,election_id;


-- the answer to the query 
insert into q7 select * from answer;
--select * from q7;
--select * from winners_comb;
--select distinct election_id,party_id from election_comb;

--select count(*) as allwinner from winners_comb;
--select count(*) as atleast from atleast_one_winner;
-- select * from atleast_one_winner;


*/