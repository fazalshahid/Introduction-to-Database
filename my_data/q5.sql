
SET SEARCH_PATH TO parlgov;
drop table if exists q5 cascade;

-- You must not change this table definition.

CREATE TABLE q5(
electionId INT, 
countryName VARCHAR(50),
winningParty VARCHAR(100),
closeRunnerUp VARCHAR(100)
);

-- Define views for your intermediate steps here.

DROP VIEW IF EXISTS election_winners CASCADE;
create view election_winners as
select election.id as election_id , cabinet_party.party_id
from election join cabinet
on election.id = cabinet.election_id
join cabinet_party
on cabinet.id = cabinet_party.cabinet_id
where cabinet_party.pm = true;

--Combining election result with country name,party name
DROP VIEW IF EXISTS election_comb CASCADE;
CREATE VIEW election_comb as 
SELECT country.name as country, election_id, alliance_id,party_id,party.name as party,election_result.id as res_id,votes
FROM election,election_result,country,party
WHERE election.id=election_result.election_id and election.country_id=country.id and election_result.party_id = party.id and election.e_type='Parliamentary election';

-- adding attributes for election winners by joining with election_comb
DROP VIEW IF EXISTS all_winners CASCADE;
CREATE VIEW all_winners AS
SELECT e.country,e.election_id,e.alliance_id,e.party_id,e.party,e.res_id,e.votes
FROM election_comb e,election_winners w where e.election_id = w.election_id and e.party_id = w.party_id;

--Winners without allowance
DROP VIEW IF EXISTS winners_na CASCADE;
CREATE VIEW winners_na AS
SELECT * FROM all_winners WHERE alliance_id is NULL AND res_id NOT IN (SELECT alliance_id FROM election_comb WHERE alliance_id IS NOT NULL);

--Winners from election winners comb with one representative from alliance
DROP VIEW IF EXISTS winners_a_one CASCADE;
CREATE VIEW winners_a_one AS
SELECT * FROM all_winners except all SELECT * FROM winners_na;

--election winners with alliance
DROP VIEW IF EXISTS winners_a CASCADE;
CREATE VIEW winners_a AS
SELECT * FROM election_comb
WHERE   (alliance_id IS NULL AND (election_id,party_id) NOT IN (SELECT election_id,party_id FROM winners_na) 
			AND (election_id,party_id) IN (SELECT election_id,party_id FROM all_winners) 
		)
		OR
		( alliance_id IS NOT NULL AND (alliance_id,election_id) in (SELECT res_id,election_id FROM all_winners)

		);


-- Assigning alliance id to head of alliances where alliance id is null for that group so that we can group them
DROP VIEW IF EXISTS winners_a_null CASCADE;
CREATE VIEW winners_a_null as
select country,election_id, res_id as alliance_id,party_id,party,res_id,votes
FROM winners_a where alliance_id IS NULL;

--Filtering the parties that are not head of the alliance
DROP VIEW IF EXISTS winners_a_not_null CASCADE;
CREATE VIEW winners_a_not_null as 
select * FROM
winners_a where alliance_id IS NOT NULL;

--Combing all the parties that formed alliance
DROP VIEW IF EXISTS winners_comb_al CASCADE;
CREATE VIEW winners_comb_al AS
select * from winners_a_null UNION ALL select * from winners_a_not_null;
-- All the winning parties that didnt form any alliance
DROP VIEW IF EXISTS winners_comb_nal CASCADE;
CREATE VIEW winners_comb_nal AS
SELECT * FROM winners_na;


--Combing all the winning parties together
DROP VIEW IF EXISTS winners_comb CASCADE;
CREATE VIEW winners_comb AS
SELECT * FROM winners_a UNION SELECT * FROM winners_na;

--All the parties that didnt win corresponding election
DROP VIEW IF EXISTS loosers CASCADE;
CREATE VIEW loosers as
SELECT * FROM election_comb EXCEPT SELECT * FROM winners_comb; 

--Summing the votes for winning alliance parties
DROP VIEW IF EXISTS winners_al_stat_aid CASCADE;
CREATE VIEW winners_al_stat_aid AS
select election_id,country,alliance_id,sum(votes) as votes
FROM winners_comb_al
GROUP BY country,election_id,alliance_id;

-- Putting the name of the party for alliances as the party which is in election winner 
DROP VIEW IF EXISTS winners_al_stat CASCADE;
CREATE VIEW winners_al_stat AS
select w.election_id,w.country,aw.party ,w.votes
FROM winners_al_stat_aid w,all_winners aw
where (w.election_id = aw.election_id);

-- Stats for single parties
DROP VIEW IF EXISTS winners_nal_stat CASCADE;
CREATE VIEW winners_nal_stat AS
SELECT election_id,country,party,votes
FROM winners_na;

-- Doing the same for loosing parties as winning parties, only putting the party name for alliance parties as party name of the head of the alliance
DROP VIEW IF EXISTS loosers_na CASCADE;
CREATE VIEW loosers_na AS
SELECT * FROM loosers
WHERE alliance_id is NULL and res_id not in(select alliance_id from loosers where alliance_id is not null);

DROP VIEW IF EXISTS loosers_a CASCADE;
CREATE VIEW loosers_a AS
SELECT * FROM loosers EXCEPT SELECT * FROM loosers_na;

DROP VIEW IF EXISTS loosers_a_null CASCADE;
CREATE VIEW loosers_a_null as
select country,election_id, res_id as alliance_id,party_id,party,res_id,votes
FROM loosers_a where alliance_id IS NULL;

DROP VIEW IF EXISTS loosers_a_not_null CASCADE;
CREATE VIEW loosers_a_not_null as 
select * FROM
loosers_a where alliance_id IS NOT NULL;

DROP VIEW IF EXISTS loosers_comb_al CASCADE;
CREATE VIEW loosers_comb_al AS
select * from loosers_a_null UNION select * from loosers_a_not_null;

DROP VIEW IF EXISTS loosers_al_stat_aid CASCADE;
CREATE VIEW loosers_al_stat_aid AS
select election_id,country,alliance_id,sum(votes) as votes
FROM loosers_comb_al
GROUP BY country,election_id,alliance_id;

-- party name is the party name of the head of the alliance
DROP VIEW IF EXISTS loosers_al_stat CASCADE;
CREATE VIEW loosers_al_stat AS
select l.election_id,l.country,e.party ,l.votes
FROM loosers_al_stat_aid l,election_comb e
where l.alliance_id = e.res_id;

DROP VIEW IF EXISTS loosers_nal_stat CASCADE;
CREATE VIEW loosers_nal_stat AS
SELECT election_id,country,party,votes
FROM loosers_na;

-- The runner up is determined at the answer view
-- Comparison for single party winner with all other single party winner
DROP VIEW IF EXISTS close_nal_nal CASCADE;
CREATE VIEW close_nal_nal AS
SELECT w.election_id as electionID,w.country as countryName,w.party as winningParty,l.party as closeRunnerUp,l.votes as l_votes
FROM winners_nal_stat w, loosers_nal_stat l
where w.election_id = l.election_id and (w.votes > l.votes) and (w.votes - l.votes) <= (0.1*w.votes);

-- Comparison for alliance winner with all other single party winner
DROP VIEW IF EXISTS close_al_nal CASCADE;
CREATE VIEW close_al_nal AS
SELECT w.election_id as electionID,w.country as countryName,w.party as winningParty,l.party as closeRunnerUp,l.votes as l_votes
FROM winners_al_stat w, loosers_nal_stat l
where w.election_id = l.election_id and (w.votes > l.votes) and (w.votes - l.votes) <= (0.1*w.votes);

-- Comparison for single party winner with all alliance winner
DROP VIEW IF EXISTS close_nal_al CASCADE;
CREATE VIEW close_nal_al AS
SELECT w.election_id as electionID,w.country as countryName,w.party as winningParty,l.party as closeRunnerUp,l.votes as l_votes
FROM winners_nal_stat w, loosers_al_stat l
where w.election_id = l.election_id and (w.votes > l.votes) and (w.votes - l.votes) <= (0.1*w.votes);

-- Comparison for alliance winner with all other single party winner
DROP VIEW IF EXISTS close_al_al CASCADE;
CREATE VIEW close_al_al AS
SELECT w.election_id as electionID,w.country as countryName,w.party as winningParty,l.party as closeRunnerUp,l.votes as l_votes
FROM winners_al_stat w, loosers_al_stat l
where w.election_id = l.election_id and (w.votes > l.votes) and (w.votes - l.votes) <= (0.1*w.votes);

--Combing all the close loosers, so that for each election we can get the runner up by taking the party with the most votes among the close loosers
DROP VIEW IF EXISTS close_loosers CASCADE;
CREATE VIEW close_loosers AS
SELECT * FROM close_nal_nal UNION SELECT * FROM close_al_nal UNION SELECT * FROM close_nal_al UNION SELECT * FROM close_al_al;

-- Here we are including only the runner up for close election results
DROP VIEW IF EXISTS answer CASCADE;
CREATE VIEW answer as 
select electionID,countryName,winningParty,closeRunnerUp
from close_loosers l1 where l_votes>=all (select l_votes from close_loosers l2 where l2.electionID=l1.electionID and l2.countryName=l1.countryName 
and l2.winningParty = l1.winningParty );
 

insert into q5 select * from answer;