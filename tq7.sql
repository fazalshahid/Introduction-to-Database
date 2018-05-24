select election.id,country.name from election,country
where elction.e_type='European Parliament' and election.country_id = country.id and country.name='Canada';
