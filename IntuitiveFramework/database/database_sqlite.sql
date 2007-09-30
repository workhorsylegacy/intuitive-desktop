
/* 
	Generate sqlite database with the command:
	sqlite3 database.sqlite < database_sqlite.sql
*/

create table users
(
	id INTEGER PRIMARY KEY,
	name varchar(255) not null,
	public_universal_key text not null,
	private_key text
);

create table documents
(
	id INTEGER PRIMARY KEY,
	name varchar(255) not null,
	user_public_key text not null,
	model_data text not null,
	state_data text not null,
	view_data text not null,
	controller_data text not null,
	controller_class_name text not null,
	model_location varchar(255) not null,
	state_location varchar(255) not null,
	controller_location varchar(255) not null
);

create table categories
(
	id INTEGER PRIMARY KEY,
	varchar name not null
);

create table deltas
(
	id INTEGER PRIMARY KEY,
	created_at timestamp not null,
	commiting_user_id int not null,
	chunk_size int not null,
	constraint fk_commiting_user_id foreign key(commiting_user_id) references Users(id)
);

create table chunks
(
    id INTEGER PRIMARY KEY,
    delta_id int not null,
    data text not null,
    line_start int not null,
    line_stop int not null,
    constraint fk_delta_id foreign key(delta_id) references Deltas(id)
);

create table groups
(
	id INTEGER PRIMARY KEY,
	name varchar(255) not null
);

create table groups_users
(
	user_id int not null,
	group_id int not null,
	constraint fk_user_d foreign key(user_id) references Users(id),
	constraint fk_group_id foreign key(group_id) references Groups(id)
);

create table categories_documents
(
	document_id int not null,
	category_id int not null,
	constraint fk_document_d foreign key(document_id) references Documents(id),
	constraint fk_category_id foreign key(category_id) references Categories(id)
);

create table documents_groups
(
	document_id int not null,
	group_id int not null,
	permissions varchar(1) not null check(permissions in('r', 'w')),
	constraint fk_document_d foreign key(document_id) references Documents(id),
	constraint fk_group_id foreign key(group_id) references Groups(id)
);

