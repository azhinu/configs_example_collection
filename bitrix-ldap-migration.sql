SET @users := 'user1,user2';
SET @ldap := 'LDAP#11'

DELETE t1 FROM b_user t1
INNER  JOIN b_user t2
WHERE
    t1.id > t2.id AND
    t1.login = t2.login;

UPDATE b_user
SET EXTERNAL_AUTH_ID = @ldap
WHERE FIND_IN_SET(b_user.login, @users);

SELECT ID,LOGIN,EXTERNAL_AUTH_ID
FROM b_user
WHERE FIND_IN_SET(b_user.login, @users);
