SET SEARCH_PATH TO parlgov;
drop table if exists q6 cascade;

-- You must not change this table definition.

CREATE TABLE q6(
countryId INT,
partyName VARCHAR(10),
number INT
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
DROP VIEW IF EXISTS intermediate_step CASCADE;

-- Define views for your intermediate steps here.


create view election_winners as
select distinct election.id as election_id , cabinet_party.party_id
from election join cabinet
on election.id = cabinet.election_id
join cabinet_party
on cabinet.id = cabinet_party.cabinet_id
where cabinet_party.pm = true;

--Combioning election result with country name,party name
CREATE VIEW election_comb as 
SELECT country.id as country, election_id, alliance_id,party_id,party.name as party,election_result.id as res_id,votes,e_date,election.previous_parliament_election_id as prev_id
FROM election,election_result,country,party
WHERE election.id=election_result.election_id and election.country_id=country.id and election_result.party_id = party.id and election.e_type='Parliamentary election'
and (election_result.election_id,election_result.party_id) in(select * from election_winners);


CREATE view election_comb_ordered as
SELECT election_id,country,party_id,e_date,prev_id FROM election_comb order by country,e_date;
--select * from election_comb_ordered;


/*
CREATE VIEW streaks as select country,party_id, count(e_date) as number
FROM election_comb_ordered e1 WHERE (prev_id,party_id) not in ( select * from election_winners) as 
	(select country,party_id,count(election_id) as number from election_comb_ordered e2 where e2.e_date < all (select e_date from election_comb_ordered e3 where
		e3.party_id != e2.party_id and e3.country=e2.country )group by country,party_id ) as b;
*/

CREATE VIEW streak_start AS
SELECT * FROM election_comb_ordered WHERE (prev_id,party_id) not in ( select * from election_winners);

CREATE VIEW streaks as select e1.country,e1.party_id, count(*) as number
FROM streak_start e1,election_comb_ordered e2 WHERE e1.country=e2.country and e1.party_id=e2.party_id and e2.e_date>=e1.e_date and 
	e2.e_date < all (select e_date from election_comb_ordered e3 where
		e3.party_id != e2.party_id and e3.country=e2.country and e3.e_date>e1.e_date ) group by e1.country,e1.party_id,e1.e_date;

CREATE VIEW max_party_streak as 
select country,party_id,max(number) as number from streaks group by country,party_id;

CREATE VIEW max_streak as select * from max_party_streak q1 where number>= all (select number from max_party_streak where country=q1.country);

CREATE VIEW answer AS
SELECT country as countryId,party.name_short as partyName, number from 
max_streak, party where max_streak.party_id=party.id;

insert into q6 select * from answer;

--select * from election_comb_ordered;


CREATE VIEW streak_row as
select ROW_NUMBER() OVER (order by country,e_date) as row,election_id,country,party_id,e_date
FROM election_comb_ordered;



select * from election where id< all (select id from election where id=100000);



--select election_id,country,party_id,e_date
--FROM election_comb_ordered order by country,e_date;


/*

CREATE VIEW streak_counts as
SELECT party_id,country,election_id,e_date,count(*) over(partition by party_id order by e_date)
from election_comb_ordered;

create view streaks as
select country,party_id,count from streak_counts
group by country,party_id,count;

create view longest_streaks as
select country,party_id,count from streaks s1
where count >= ALL (select count from streaks s2 where s2.country=s1.country );




CREATE FUNCTION get_streak(int) RETURNS int AS $$
DECLARE
    num int :=0;
    a election%ROWTYPE;
BEGIN

	create view bbbb AS
		select * from election;
	

	for a in select * from election
	loop
	num=num+1;
	end loop;
    RETURN num;
END;
$$ LANGUAGE plpgsql;

--select * from election_comb_ordered;

--select * from streak_row;

--SELECT * from streaks;

--select * from longest_streaks;


-- the answer to the query 
--insert into q6 



select * from election where id=get_streak(10);
*/