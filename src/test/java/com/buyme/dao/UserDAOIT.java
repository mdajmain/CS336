package com.buyme.dao;

import com.buyme.model.User;
import com.buyme.util.DatabaseConnection;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;

import java.sql.Connection;
import java.sql.PreparedStatement;

import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;

class UserDAOIT {

    private final UserDAO userDAO = new UserDAO();
    private String username;

    @AfterEach
    void tearDown() throws Exception {
        if (username == null) return;
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement endUser = conn.prepareStatement(
                 "DELETE FROM end_user WHERE userID = (SELECT userID FROM user WHERE username = ?)");
             PreparedStatement user = conn.prepareStatement("DELETE FROM user WHERE username = ?")) {
            endUser.setString(1, username);
            endUser.executeUpdate();
            user.setString(1, username);
            user.executeUpdate();
        }
    }

    @Test
    void register_hashesPassword_andLoginSucceedsWithThePlaintextPassword() {
        username = "it_bcrypt_user_" + System.nanoTime();
        User newUser = new User(username, "correct-horse-battery-staple", username + "@example.com", "end_user");
        newUser.setFirstName("IT");
        newUser.setLastName("Test");

        boolean registered = userDAO.register(newUser);
        assertNotNull(registered);

        User loggedIn = userDAO.login(username, "correct-horse-battery-staple");
        assertNotNull(loggedIn, "login should succeed with the original plaintext password");
    }

    @Test
    void login_failsCleanlyWithWrongPassword() {
        username = "it_bcrypt_wrong_" + System.nanoTime();
        User newUser = new User(username, "the-real-password", username + "@example.com", "end_user");
        userDAO.register(newUser);

        User loggedIn = userDAO.login(username, "not-the-real-password");
        assertNull(loggedIn, "login should return null, not throw, on a wrong password");
    }
}
