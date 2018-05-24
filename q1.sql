SET SEARCH_PATH TO parlgov;
drop table if exists q1 cascade;

-- You must not change this table definition.

create table q1(
century VARCHAR(2),
country VARCHAR(50), 
left_right REAL, 
state_market REAL, 
liberty_authority REAL
);


-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
DROP VIEW IF EXISTS intermediate_step CASCADE;

-- Define views for your intermediate steps here.
-- get all of the winning parties based on the cabinet
create view election_winners as
select election.id as election_id , cabinet_party.party_id
from election join cabinet
on election.id = cabinet.election_id
join cabinet_party
on cabinet.id = cabinet_party.cabinet_id
where cabinet_party.pm = true;

CREATE VIEW alliance_parties as
SELECT  election_id,party_id,alliance_id
FROM election_result
WHERE alliance_id IS NOT NULL;

CREATE VIEW alliance_stats as
SELECT CASE WHEN EXTRACT(year FROM e_date)>=1901 AND EXTRACT(year FROM e_date) <=2000 THEN '20'
            ELSE '21' END AS century,
            country.name as country,avg(left_right) as left_right ,avg(state_market) as state_market ,avg(liberty_authority) as liberty_authority
FROM alliance_parties,party_position,election_winners,country,election,party
WHERE alliance_parties.party_id=party_position.party_id AND alliance_parties.election_id=election.id AND 
election_winners.election_id=election.id AND election.country_id=country.id AND election_winners.party_id=party.id and party.id=party_position.party_id
AND EXTRACT(year FROM e_date)>=1901 AND EXTRACT(year FROM e_date) <=2100 AND election.e_type='Parliamentary election' 
GROUP BY alliance_parties.alliance_id,century,country;


--CREATE VIEW election_stats as
CREATE VIEW party_stats as
SELECT CASE WHEN EXTRACT(year FROM e_date)>=1901 AND EXTRACT(year FROM e_date) <=2000 THEN '20'
            ELSE '21' END AS century,
            country.name as country,left_right ,state_market ,liberty_authority
FROM election_winners,election,party,country,party_position
WHERE election_winners.election_id=election.id AND election.country_id=country.id AND election_winners.party_id=party.id and party.id=party_position.party_id
AND EXTRACT(year FROM e_date)>=1901 AND EXTRACT(year FROM e_date) <=2100 AND election.e_type='Parliamentary election' AND (election.id,party.id) NOT IN (SELECT election_id,party_id FROM alliance_parties)
;

CREATE VIEW combined_stats as
(SELECT * FROM alliance_stats) UNION ALL (SELECT * FROM party_stats);

insert into q1 
SELECT century,country,avg(left_right),avg(state_market),avg(liberty_authority)
FROM combined_stats
GROUP BY century,country;




-- the answer to the query 
/*insert into q1 */

