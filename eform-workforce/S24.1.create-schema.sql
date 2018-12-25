CREATE SCHEMA IF NOT EXISTS custom AUTHORIZATION camunda;
SET search_path TO custom;

CREATE TABLE TENANT_MANAGEMENT (
    ID_ SERIAL PRIMARY KEY,
    NAME_ varchar(255),
    PARENT_ID_ INT,
    FOREIGN KEY (PARENT_ID_) REFERENCES TENANT_MANAGEMENT(ID_)
);
CREATE INDEX TENANT_MANAGEMENT_ID on TENANT_MANAGEMENT(ID_);
ALTER TABLE TENANT_MANAGEMENT OWNER TO camunda;

CREATE TABLE RUNTIME_TENANT (
    ID_ SERIAL PRIMARY KEY,
    NAME_ varchar(255)
);
CREATE INDEX RUNTIME_TENANT_ID on RUNTIME_TENANT(ID_);
ALTER TABLE RUNTIME_TENANT OWNER TO camunda;
