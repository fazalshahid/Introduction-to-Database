
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
	AND election_result.election_id=election.id
	AND election.country_id=country.id
	AND election.e_type='Parliamentary election';


CREATE VIEW Party_group as
SELECT country,electoral_system,
	CASE WHEN count(party_id)=1 THEN '1'
		 WHEN count(party_id)>=2 AND count(party_id)<=3 THEN '2_3'
		 WHEN count(party_id)>=4 AND count(party_id)<=5 THEN '4_5'
		 WHEN count(party_id)>=6 THEN '6+' 
		 END AS num_party         
FROM alliance_parties
GROUP BY country,electoral_system,alliance_id,election_id;

CREATE VIEW Party_stat as
SELECT country,electoral_system,num_party, 
	CASE WHEN num_party='1' THEN count(num_party) ELSE 0 as single_party,
	CASE WHEN num_party='2_3' THEN count(num_party) ELSE 0 as two_to_three,
	CASE WHEN num_party='4_5' THEN count(num_party) ELSE 0 as four_to_five,
	CASE WHEN num_party='6+' THEN count(num_party) ELSE 0 as six_or_more,
FROM Party_group
GROUP BY country,electoral_system,num_party;

CREATE VIEW single_party_r as
SELECT country,electoral_system,num_alliance as single_party
FROM Party_stat
WHERE num_party='1';

CREATE VIEW two_to_three_r as
SELECT country,electoral_system,num_alliance as two_to_three
FROM Party_stat
WHERE num_party='2_3';

CREATE VIEW four_to_five_r as
SELECT country,electoral_system,num_alliance as four_to_five
FROM Party_stat
WHERE num_party='4_5';

CREATE VIEW six_or_more_r as
SELECT country,electoral_system,num_alliance as six_or_more
FROM Party_stat
WHERE num_party='6+';


insert into q2 SELECT DISTINCT country.name as country,electoral_system
	FROM country,election
	WHERE election.country_id=country.id AND election.e_type='Parliamentary election'
	

/*

-- the answer to the query 
insert into q2
SELECT single_party_r.country,single_party_r.electoral_system,single_party,two_to_three,four_to_five,six_or_more
FROM single_party_r NATURAL JOIN two_to_three_r NATURAL JOIN four_to_five_r NATURAL JOIN six_or_more_r;

SELECT * FROM single_party_r;
SELECT * FROM two_to_three_r;
SELECT * FROM four_to_five_r;
SELECT * FROM six_or_more_r;
SELECT * FROM Party_group where alliance_id is NULL;

*/