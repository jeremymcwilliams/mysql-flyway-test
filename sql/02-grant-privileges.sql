-- Grant the user ability to create databases
GRANT ALL PRIVILEGES ON *.* TO 'fakeAirbnbUser'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;