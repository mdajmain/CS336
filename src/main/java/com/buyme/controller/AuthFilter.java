// File: src/main/java/com/buyme/controller/AuthFilter.java
package com.buyme.controller;

import com.buyme.model.User;

import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.annotation.WebFilter;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.util.Set;

/**
 * Single access-control checkpoint replacing the per-page session-check
 * scriptlets that used to open every protected JSP. Role requirement is
 * derived from the request path:
 *  - /admin/*                         -> "admin"
 *  - /rep/*                           -> "customer_rep"
 *  - the end_user-restricted paths    -> "end_user"
 *  - everything else in urlPatterns   -> any logged-in user
 *
 * auction/view.jsp, auction/bid-history.jsp, auction/similar.jsp, index.jsp,
 * login.jsp and register.jsp are intentionally NOT in urlPatterns - they were
 * public before this filter existed and must stay public.
 */
@WebFilter(urlPatterns = {
    "/admin/*",
    "/rep/*",
    "/account.jsp",
    "/auction-details.jsp",
    "/browse.jsp",
    "/change-password.jsp",
    "/create-auction.jsp",
    "/dashboard.jsp",
    "/edit-account.jsp",
    "/my-alerts.jsp",
    "/my-auctions.jsp",
    "/my-bids.jsp",
    "/notifications.jsp",
    "/questions.jsp",
    "/seller-close-auction.jsp",
    "/user-auctions.jsp",
    "/auction/my-auctions.jsp",
    "/auction/create.jsp",
    "/auction/edit.jsp",
    "/auction/cancel.jsp",
    "/auction/my-bids.jsp"
})
public class AuthFilter implements Filter {

    private static final Set<String> END_USER_ONLY_PATHS = Set.of(
        "/my-auctions.jsp",
        "/auction/my-auctions.jsp",
        "/auction/create.jsp",
        "/auction/edit.jsp",
        "/auction/cancel.jsp",
        "/auction/my-bids.jsp"
    );

    @Override
    public void init(FilterConfig filterConfig) {
    }

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        HttpServletRequest req = (HttpServletRequest) request;
        HttpServletResponse res = (HttpServletResponse) response;

        String path = req.getServletPath();
        String requiredRole = requiredRoleFor(path);

        HttpSession session = req.getSession(false);
        User user = session != null ? (User) session.getAttribute("user") : null;

        boolean authorized = user != null
            && (requiredRole == null || requiredRole.equalsIgnoreCase(user.getUserType()));

        if (!authorized) {
            res.sendRedirect(req.getContextPath() + "/login");
            return;
        }

        chain.doFilter(request, response);
    }

    private String requiredRoleFor(String path) {
        if (path.startsWith("/admin/")) {
            return "admin";
        }
        if (path.startsWith("/rep/")) {
            return "customer_rep";
        }
        if (END_USER_ONLY_PATHS.contains(path)) {
            return "end_user";
        }
        return null; // any logged-in user
    }

    @Override
    public void destroy() {
    }
}
