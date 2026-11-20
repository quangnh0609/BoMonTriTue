IF OBJECT_ID(N'dbo.bet_api_football_fixture', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.bet_api_football_fixture (
        [match] varchar(16) NOT NULL PRIMARY KEY,
        fixture_id bigint NOT NULL UNIQUE CHECK (fixture_id > 0)
    );
END;
