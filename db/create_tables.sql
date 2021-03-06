# Our script for creating our tables

USE censusdat;

CREATE TABLE user_profiles
(
	uid INT AUTO_INCREMENT PRIMARY KEY,
	username VARCHAR(32) NOT NULL UNIQUE,
	firstName VARCHAR(32) NOT NULL,
	lastName VARCHAR(32) NOT NULL,
	password_hash VARCHAR(100) NOT NULL,
	salt CHAR(16) NOT NULL,
	num_queries INT NOT NULL DEFAULT 0
);

# One login per user, 1-to-1 mapping
CREATE TABLE login_tokens
(
    username VARCHAR(32) NOT NULL UNIQUE,
    token VARCHAR(64) NOT NULL PRIMARY KEY,
    FOREIGN KEY (username) REFERENCES user_profiles(username)
);

CREATE TABLE saved_queries
(
	qid INT AUTO_INCREMENT PRIMARY KEY,
	uid INT NOT NULL,
	last_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP(),
	query JSON NOT NULL,
    FOREIGN KEY (uid) REFERENCES user_profiles(uid)
);

# ISO-3166-1 Country codes
CREATE TABLE country_codes_lut
(
    code CHAR(3) NOT NULL PRIMARY KEY, # ISO 3166-1 Country Code (Alpha 3)
    display_name VARCHAR(128) NOT NULL
);

CREATE TABLE age_range_lut
(
    id INT NOT NULL PRIMARY KEY,
    age_start INT NOT NULL,
    age_end INT NOT NULL,
    display_name VARCHAR(128) NOT NULL
);

CREATE TABLE sex_lut
(
    id CHAR(1) NOT NULL PRIMARY KEY,
    display_name VARCHAR(128) NOT NULL
);

CREATE TABLE education_level_lut
(
    id CHAR(2) NOT NULL PRIMARY KEY,
    display_name VARCHAR(128) NOT NULL
);

CREATE TABLE geocode_lut
(
  geocode VARCHAR(64) NOT NULL PRIMARY KEY,
  geoname VARCHAR(128) NOT NULL,
  lon DOUBLE NOT NULL,
  lat DOUBLE NOT NULL
);

CREATE TABLE labour_lut
(
    id INT NOT NULL PRIMARY KEY,
    display_name VARCHAR(128) NOT NULL
);

CREATE TABLE income_meta_lut
(
    id INT NOT NULL PRIMARY KEY,
    display_name VARCHAR(128) NOT NULL
);


# Actual dataset table definitions

CREATE TABLE individual_incomes
(
    id INT AUTO_INCREMENT PRIMARY KEY,
    age INT NOT NULL,
    sex CHAR(1) NOT NULL,
    year INT NOT NULL CHECK (year >= 1900),
    region CHAR(3) NOT NULL,
    geocode VARCHAR(64) NOT NULL,
    value INT NOT NULL, # Absolute number (population value)
    meta CHAR(2) NOT NULL,
    FOREIGN KEY (geocode) REFERENCES geocode_lut(geocode),
    FOREIGN KEY (age) REFERENCES age_range_lut(id),
    FOREIGN KEY (sex) REFERENCES sex_lut(id),
    FOREIGN KEY (region) REFERENCES country_codes_lut(code),
    FOREIGN KEY (meta) REFERENCES income_meta_lut(id)
);

CREATE TABLE education
(
    id INT AUTO_INCREMENT PRIMARY KEY,
    age INT NOT NULL,
    sex CHAR(1) NOT NULL,
    year INT NOT NULL CHECK (year >= 1900),
    region CHAR(3) NOT NULL,
    geocode VARCHAR(64) NOT NULL,
    value INT NOT NULL, # Absolute number (population value)
    meta CHAR(2) NOT NULL,
    FOREIGN KEY (geocode) REFERENCES geocode_lut(geocode),
    FOREIGN KEY (age) REFERENCES age_range_lut(id),
    FOREIGN KEY (sex) REFERENCES sex_lut(id),
    FOREIGN KEY (region) REFERENCES country_codes_lut(code),
    FOREIGN KEY (meta) REFERENCES education_level_lut(id)
);

CREATE TABLE employment
(
    id INT AUTO_INCREMENT PRIMARY KEY,
    age INT NOT NULL,
    sex CHAR(1) NOT NULL,
    year INT NOT NULL CHECK (year >= 1900),
    region CHAR(3) NOT NULL,
    geocode VARCHAR(64) NOT NULL,
    value INT NOT NULL, # Absolute number (population value)
    meta INT NOT NULL,
    FOREIGN KEY (geocode) REFERENCES geocode_lut(geocode),
    FOREIGN KEY (age) REFERENCES age_range_lut(id),
    FOREIGN KEY (sex) REFERENCES sex_lut(id),
    FOREIGN KEY (region) REFERENCES country_codes_lut(code),
    FOREIGN KEY (meta) REFERENCES labour_lut(id)
);

CREATE TABLE population
(
    id INT AUTO_INCREMENT PRIMARY KEY,
    age INT NOT NULL,
    sex CHAR(1) NOT NULL,
    year INT NOT NULL CHECK (year >= 1900),
    region CHAR(3) NOT NULL,
    geocode VARCHAR(64) NOT NULL,
    value INT NOT NULL, # Absolute number (population value)
    meta INT NOT NULL, # No associated meta with population
    FOREIGN KEY (geocode) REFERENCES geocode_lut(geocode),
    FOREIGN KEY (age) REFERENCES age_range_lut(id),
    FOREIGN KEY (sex) REFERENCES sex_lut(id),
    FOREIGN KEY (region) REFERENCES country_codes_lut(code)
);

# User friends relation
create table user_friends
(
    follower int not null,
    followee int not null,
    primary key(followee, follower),
    constraint user_friends_user_profiles_uid_fk
        foreign key (follower) references user_profiles (uid),
    constraint user_friends_user_profiles_uid_fk_2
        foreign key (followee) references user_profiles (uid)
);

# Shared queries relation
create table shared_queries
(
    qid int not null,
    uid int not null,
    primary key(qid, uid),
    constraint shared_queries_saved_queries_qid_fk
        foreign key (qid) references saved_queries (qid) on delete cascade ,
    constraint shared_queries_user_profiles_uid_fk
        foreign key (uid) references user_profiles (uid) on delete cascade
);

# No need to create manual indices; the above tables
# already have indices on all of their keys (primary + foreign)

# Triggers to maintain the number of queries for each user
CREATE TRIGGER increase_user_num_queries
    AFTER INSERT ON saved_queries
    FOR EACH ROW
    UPDATE user_profiles SET num_queries = num_queries + 1 WHERE uid = NEW.uid;

CREATE TRIGGER decrease_user_num_queries
    AFTER DELETE ON saved_queries
    FOR EACH ROW
    UPDATE user_profiles SET num_queries = num_queries - 1 WHERE uid = OLD.uid;

# Trigger to auto update last_modified time for saved queries
CREATE TRIGGER update_last_mod_time_queries
    BEFORE UPDATE ON saved_queries
    FOR EACH ROW
    SET NEW.last_updated = CURRENT_TIMESTAMP();

# Indices on the main queried parameters of the datasets:
CREATE INDEX education_meta_age_sex_index
	ON education (meta, age, sex);

CREATE INDEX employment_meta_age_sex_index
	ON employment (meta, age, sex);

CREATE INDEX individual_incomes_meta_age_sex_index
	ON individual_incomes (meta, age, sex);

CREATE INDEX population_meta_age_sex_index
	ON population (meta, age, sex);

CREATE INDEX population_meta_age_sex_geocode_index
    ON population (meta, age, sex, geocode);
