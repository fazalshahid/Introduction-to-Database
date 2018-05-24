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
/*
CREATE VIEW alliance_parties as
SELECT country.name as country,electoral_system,election_result.alliance_id,election_result.party_id,election.id AS election_id
FROM election_winners,election,election_result,cabinet,country
WHERE election_winners.election_id=election_result.election_id 
	AND election_result.election_id=election.id
	AND election.id = election_winners.election_id
	AND election_winners.party_id=election_result.party_id
	AND cabinet.election_id=election.id
	AND cabinet.country_id=country.id
	AND election.e_type='Parliamentary election';




CREATE VIEW alliance_parties as
SELECT election_result.alliance_id,election_result.party_id,election_result.election_id AS election_id
FROM election_winners JOIN election_result on election_winners.election_id =election_result.election_id AND election_winners.party_id=election_result.party_id
;

CREATE VIEW alliance_parties as
SELECT country.name as country,electoral_system,election_result.alliance_id,election_result.party_id,election.id AS election_id
FROM election_winners JOIN election_result on election_winners.election_id=election_result.election_id and election_winners.party_id=election_result.party_id JOIN election on election_winners.election_id=election.id
	JOIN country ON country.id=election.country_id
where election.e_type='Parliamentary election';
*/
CREATE VIEW alliance_parties as
SELECT country.name as country,electoral_system,election_result.alliance_id,election_result.party_id,election.id AS election_id
FROM election_result JOIN election on election_result.election_id=election.id
	JOIN country ON country.id=election.country_id 
where election.e_type='Parliamentary election' and (election.id,election_result.party_id) in (select election_id,party_id from election_winners);


CREATE VIEW Party_group as
SELECT country,electoral_system,election_id,alliance_id,
	CASE WHEN count(party_id)=1 THEN '1'
		 WHEN count(party_id)>=2 AND count(party_id)<=3 THEN '2_3'
		 WHEN count(party_id)>=4 AND count(party_id)<=5 THEN '4_5'
		 WHEN count(party_id)>=6 THEN '6+'
		  WHEN count(party_id)<1 THEN '0'
		 END AS num_party,count(party_id) as c         
FROM alliance_parties
GROUP BY country,electoral_system,election_id,alliance_id;

CREATE VIEW single_party_r as
	select country,electoral_system,count(distinct election_id ) as single_party
	from Party_group where num_party='1'
	group by country,electoral_system;


CREATE VIEW two_to_three_r as
	select country,electoral_system,count(distinct election_id ) as two_to_three
	from Party_group where num_party='2_3'
	group by country,electoral_system;

CREATE VIEW four_to_five_r as
	select country,electoral_system,count(distinct election_id) as four_to_five
	from Party_group where num_party='4_5' 
	group by country,electoral_system;

CREATE VIEW six_or_more_r as
	select country,electoral_system,count(distinct election_id) as six_or_more
	from Party_group where num_party='6+'
	group by country,electoral_system; 

INSERT INTO q2 SELECT DISTINCT country.name as country,electoral_system FROM election,country where country.id=election.country_id;
UPDATE q2 SET single_party = (SELECT single_party from single_party_r WHERE single_party_r.country=q2.country);
UPDATE q2 SET two_to_three = (SELECT two_to_three from two_to_three_r WHERE two_to_three_r.country=q2.country);
UPDATE q2 SET four_to_five = (SELECT four_to_five from four_to_five_r WHERE four_to_five_r.country=q2.country);
UPDATE q2 SET six_or_more = (SELECT six_or_more from six_or_more_r WHERE six_or_more_r.country=q2.country);

UPDATE q2 set single_party=0 where single_party is NULL;

UPDATE q2 set two_to_three=0 where two_to_three is NULL;

UPDATE q2 set four_to_five=0 where four_to_five is NULL;

UPDATE q2 set six_or_more=0 where six_or_more is NULL;


create view NumElection as 
	select country.name as country ,count(distinct election.id)
	from election,country where election.e_type='Parliamentary election' and election.country_id=country.id
	group by country.name ;

--SELECT * FROM NumElection;


--SELECT * FROM q2;

--select election_id,party_id from alliance_parties except select election_id,party_id from election_winners;

--select * from Party_group where country = 'France';
--select * from alliance_parties where country = 'France' ;

/*
select count(party_id),count(distinct party_id) from election_winners,election
where election_winners.election_id=election.id;
select count(party_id),count(distinct party_id) from election_winners,election
where election_winners.election_id=election.id and election.e_type='Parliamentary election';

select count(party_id),count(distinct party_id) from election_winners,election
where election_winners.election_id=election.id and election.e_type='European Parliament';
*/
--select distinct(election_id,party_id) from election_winners except select distinct(election_id,party_id) from election_result;


-- the answer to the query 


--SELECT single_party_r.country,single_party_r.electoral_system,single_party,two_to_three,four_to_five,six_or_more
--FROM single_party_r NATURAL JOIN two_to_three_r NATURAL JOIN four_to_five_r NATURAL JOIN six_or_more_r;





