
SET SEARCH_PATH TO parlgov;
drop table if exists q6 cascade;

-- You must not change this table definition.

CREATE TABLE q6(
countryId INT,
partyName VARCHAR(10),
number INT
);

-- Define views for your intermediate steps here.

DROP VIEW IF EXISTS election_winners CASCADE;
create view election_winners as
select distinct election.id as election_id , cabinet_party.party_id
from election join cabinet
on election.id = cabinet.election_id
join cabinet_party
on cabinet.id = cabinet_party.cabinet_id
where cabinet_party.pm = true;

--Combining election result with country name,party name
DROP VIEW IF EXISTS election_comb CASCADE;
CREATE VIEW election_comb as 
SELECT country.id as country, election_id, alliance_id,party_id,party.name as party,election_result.id as res_id,votes,e_date,election.previous_parliament_election_id as prev_id
FROM election,election_result,country,party
WHERE election.id=election_result.election_id and election.country_id=country.id and election_result.party_id = party.id and election.e_type='Parliamentary election'
and (election_result.election_id,election_result.party_id) in(select * from election_winners);

--Didnt need at the end
--Sorting the elections based on the dates
DROP VIEW IF EXISTS election_comb_ordered CASCADE;
CREATE view election_comb_ordered as
SELECT election_id,country,party_id,e_date,prev_id FROM election_comb order by country,e_date;

--Filtering the elections where a streak started
-- A streak starts when prev_id is null or first election
--Or party didnt win the last election
-- the purpose of this view is to distinguish different straks and group by streak start election
DROP VIEW IF EXISTS streak_start CASCADE;
CREATE VIEW streak_start AS
SELECT * FROM election_comb_ordered WHERE prev_id is null or (prev_id,party_id) not in ( select * from election_winners);

-- Streak counts for each countries
-- we are comparing streak start with all election wins and selecting all the consecutive wins after the each streak start 
DROP VIEW IF EXISTS streaks CASCADE;
CREATE VIEW streaks as select e1.country,e1.party_id, count(*) as number
FROM streak_start e1,election_comb_ordered e2 WHERE e1.country=e2.country and e1.party_id=e2.party_id and e2.e_date>=e1.e_date and 
	(e2.e_date < all (select e_date from election_comb_ordered e3 where
		e3.party_id != e2.party_id and e3.country=e2.country and e3.e_date>e1.e_date ) 
	or not exists (select * from election_comb_ordered e4 where e4.party_id != e2.party_id and e4.country=e2.country and e4.e_date>e1.e_date))

	group by e1.country,e1.party_id,e1.e_date;

--maximum streak for each party
DROP VIEW IF EXISTS max_party_streak CASCADE;
CREATE VIEW max_party_streak as 
select country,party_id,max(number) as number from streaks group by country,party_id;

--The party with the longest streak among all the parties for each country
DROP VIEW IF EXISTS max_streak CASCADE;
CREATE VIEW max_streak as select * from max_party_streak q1 where number>= all (select number from max_party_streak where country=q1.country);

--Renaming attributes for final answer
DROP VIEW IF EXISTS answer CASCADE;
CREATE VIEW answer AS
SELECT country as countryId,party.name_short as partyName, number from 
max_streak, party where max_streak.party_id=party.id;

insert into q6 select * from answer;

