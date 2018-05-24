SET SEARCH_PATH TO parlgov;
drop table if exists q5 cascade;

-- You must not change this table definition.

CREATE TABLE q5(
electionId INT, 
countryName VARCHAR(50),
winningParty VARCHAR(100),
closeRunnerUp VARCHAR(100)
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
DROP VIEW IF EXISTS intermediate_step CASCADE;

-- Define views for your intermediate steps here.

create view election_winners as
select election.id as election_id , cabinet_party.party_id
from election join cabinet
on election.id = cabinet.election_id
join cabinet_party
on cabinet.id = cabinet_party.cabinet_id
where cabinet_party.pm = true;

--Combioning election result with country name,party name
CREATE VIEW election_comb as 
SELECT country.name as country, election_id, alliance_id,party_id,party.name as party,election_result.id as res_id,votes
FROM election,election_result,country,party
WHERE election.id=election_result.election_id and election.country_id=country.id and election_result.party_id = party.id and election.e_type='Parliamentary election';

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


-- Assigning alliance id to where alliance id is null for that group so that we can group them

--UPDATE winners_a set alliance_id= res_id where alliance_id is NULL;

CREATE VIEW winners_a_null as
select country,election_id, res_id as alliance_id,party_id,party,res_id,votes
FROM winners_a where alliance_id IS NULL;

CREATE VIEW winners_a_not_null as 
select * FROM
winners_a where alliance_id IS NOT NULL;

CREATE VIEW winners_comb_al AS
select * from winners_a_null UNION select * from winners_a_not_null;

CREATE VIEW winners_comb_nal AS
SELECT * FROM winners_na;

CREATE VIEW winners_comb AS
SELECT * FROM winners_a UNION SELECT * FROM winners_na;

CREATE VIEW loosers as
SELECT * FROM election_comb EXCEPT SELECT * FROM winners_comb; 


CREATE VIEW winners_al_stat_aid AS
select election_id,country,alliance_id,count(votes) as votes
FROM winners_comb_al
GROUP BY country,election_id,alliance_id;

CREATE VIEW winners_al_stat AS
select w.election_id,w.country,e.party ,w.votes
FROM winners_al_stat_aid w,election_comb e
where w.alliance_id = e.res_id;

CREATE VIEW winners_nal_stat AS
SELECT election_id,country,party,votes
FROM winners_na;

CREATE VIEW loosers_na AS
SELECT * FROM loosers
WHERE alliance_id is NULL and res_id not in(select alliance_id from loosers where alliance_id is not null);

CREATE VIEW loosers_a AS
SELECT * FROM loosers EXCEPT SELECT * FROM loosers_na;

CREATE VIEW loosers_a_null as
select country,election_id, res_id as alliance_id,party_id,party,res_id,votes
FROM loosers_a where alliance_id IS NULL;

CREATE VIEW loosers_a_not_null as 
select * FROM
loosers_a where alliance_id IS NOT NULL;

CREATE VIEW loosers_comb_al AS
select * from loosers_a_null UNION select * from loosers_a_not_null;

CREATE VIEW loosers_al_stat_aid AS
select election_id,country,alliance_id,count(votes) as votes
FROM loosers_comb_al
GROUP BY country,election_id,alliance_id;

CREATE VIEW loosers_al_stat AS
select l.election_id,l.country,e.party ,l.votes
FROM loosers_al_stat_aid l,election_comb e
where l.alliance_id = e.res_id;

CREATE VIEW loosers_nal_stat AS
SELECT election_id,country,party,votes
FROM loosers_na;
--SELECT * FROM winners_comb order by country,election_id;

--SELECT * FROM winners_comb order by country,election_id;
--SELECT * FROM winners_na order by country,election_id;
-- comparison between nal parties
CREATE VIEW close_nal_nal AS
SELECT w.election_id as electionID,w.country as countryName,w.party as winningParty,l.party as closeRunnerUp
FROM winners_nal_stat w, loosers_nal_stat l
where w.election_id = l.election_id and (w.votes - l.votes) <= (0.1*w.votes);

CREATE VIEW close_al_nal AS
SELECT w.election_id as electionID,w.country as countryName,w.party as winningParty,l.party as closeRunnerUp
FROM winners_al_stat w, loosers_nal_stat l
where w.election_id = l.election_id and (w.votes - l.votes) <= (0.1*w.votes);

CREATE VIEW close_nal_al AS
SELECT w.election_id as electionID,w.country as countryName,w.party as winningParty,l.party as closeRunnerUp
FROM winners_nal_stat w, loosers_al_stat l
where w.election_id = l.election_id and (w.votes - l.votes) <= (0.1*w.votes);

CREATE VIEW close_al_al AS
SELECT w.election_id as electionID,w.country as countryName,w.party as winningParty,l.party as closeRunnerUp
FROM winners_al_stat w, loosers_al_stat l
where w.election_id = l.election_id and (w.votes - l.votes) <= (0.1*w.votes);

CREATE VIEW answer AS
SELECT * FROM close_nal_nal UNION SELECT * FROM close_al_nal UNION SELECT * FROM close_nal_al UNION SELECT * FROM close_al_al;
insert into q5 select * from answer;

/*
CREATE VIEW close_al_nal_head AS
select c.electionID,c.countryName,e.party as winningParty,c.closeRunnerUp
FROM close_al_nal c,election_comb e
where c.winningAID = e.res_id;

CREATE VIEW close_nal_al_head AS
select c.electionID,c.countryName,c.party,e.party as closeRunnerUp
FROM close_nal_al c,election_comb e
where c.loosingAID = e.res_id;

CREATE VIEW close_al_al_head AS
select c.electionID,c.countryName,c.party,e.party as closeRunnerUp
FROM close_nal_al c,election_comb e
where c.loosingAID = e.res_id;
*/














-- the answer to the query 
--insert into q5 

select * from all_winners;


