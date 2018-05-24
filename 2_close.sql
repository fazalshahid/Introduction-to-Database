SET SEARCH_PATH TO parlgov;
drop table if exists q2 cascade;

-- You must not change this table definition.

create table q2(
country VARCHAR(50),
electoral_system VARCHAR(100),
single_party INT,
two_to_three INT,
four_to_five INT,
six_or_more INT
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

CREATE VIEW alliance_parties as
SELECT country.name as country,electoral_system,election_result.alliance_id,election_result.party_id,election.id AS election_id
FROM election,election_result,country,election_winners
WHERE election_winners.election_id=election.id
	AND election_winners.party_id=election_result.party_id 
	AND election_result.election_id=election.id
	AND election.country_id=country.id
	AND election.e_type='Parliamentary election';


CREATE VIEW Party_group as
SELECT country,electoral_system,election_id,alliance_id,
	CASE WHEN count(party_id)=1 THEN '1'
		 WHEN count(party_id)>=2 AND count(party_id)<=3 THEN '2_3'
		 WHEN count(party_id)>=4 AND count(party_id)<=5 THEN '4_5'
		 WHEN count(party_id)>=6 THEN '6+' 
		 END AS num_party         
FROM alliance_parties
GROUP BY country,electoral_system,alliance_id,election_id;

CREATE VIEW single_party_r as
	select country,electoral_system,count(election_id) as single_party
	from Party_group where num_party='1'
	group by country,electoral_system;


CREATE VIEW two_to_three_r as
	select country,electoral_system,count(election_id) as two_to_three
	from Party_group where num_party='2_3'
	group by country,electoral_system;

CREATE VIEW four_to_five_r as
	select country,electoral_system,count(election_id)
	from Party_group where num_party='4_5' as four_to_five
	group by country,electoral_system;

CREATE VIEW six_or_more_r as
	select country,electoral_system,count(election_id)
	from Party_group where num_party='6+' as six_or_more
	group by country,electoral_system;

INSERT INTO q2 SELECT DISTINCT country FROM election,country where country.id=election.country_id;
UPDATE q2 SET single_party = (SELECT single_party from single_party_r WHERE single_party_r.country=q2.country);
UPDATE q2 SET two_to_three = (SELECT two_to_three from two_to_three_r WHERE two_to_three_r.country=q2.country);
UPDATE q2 SET four_to_five = (SELECT four_to_five from four_to_five_r WHERE four_to_five_r.country=q2.country);
UPDATE q2 SET six_or_more = (SELECT six_or_more from six_or_more_r WHERE six_or_more_r.country=q2.country);







-- the answer to the query 


--SELECT single_party_r.country,single_party_r.electoral_system,single_party,two_to_three,four_to_five,six_or_more
--FROM single_party_r NATURAL JOIN two_to_three_r NATURAL JOIN four_to_five_r NATURAL JOIN six_or_more_r;


