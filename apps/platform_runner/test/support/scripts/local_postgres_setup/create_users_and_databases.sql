--- This script is for setting up users and databases for local testing of the platform --

create user acquire_app_user with password 'acquire123';
create database acquire_app_state with owner acquire_app_user;

create user broadcast_app_user with password 'broadcast123';
create database broadcast_app_state with owner broadcast_app_user;

create user define_app_user with password 'define123';
create database define_app_state with owner define_app_user;

create user gather_app_user with password 'gather123';
create database gather_app_state with owner gather_app_user;

create user orchestrate_app_user with password 'orchestrate123';
create database orchestrate_app_state with owner orchestrate_app_user;

create user persist_app_user with password 'persist123';
create database persist_app_state with owner persist_app_user;

create user profile_app_user with password 'profile123';
create database profile_app_state with owner profile_app_user;

create user receive_app_user with password 'receive123';
create database receive_app_state with owner receive_app_user;
