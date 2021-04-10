DROP DATABASE IF EXISTS user_db;
CREATE DATABASE IF NOT EXISTS user_db;

USE user_db;

SELECT 'CREATING DATABASE STRUCTURE' as 'INFO';

DROP TABLE IF EXISTS users
CREATE TABLE users (
  user_num        INT                     CHECK(user_num > 0);
  user_email      VARCHAR(50)             NOT NULL;
  signup_date     DATE                    NOT NULL;
  renewal_data    DATE                    NOT NULL;
  vip_flag        BIT                     NOT NULL;
  PRIMARY KEY     (user_num)
  UNIQUE  KEY     (user_email)
);

