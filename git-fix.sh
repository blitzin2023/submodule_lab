#*  @brief        git有关的修复命令
#!/bin/sh
# fix folling case:
#   unable to access 'https://github.com/.../.git': Could not resolve host: github.com
#   gnutls_handshake() failed: The TLS connection was non-properly terminated.
function git-fix-github ()
{
    cat <<EOF
try fixing folling case:
    unable to access 'https://github.com/.../.git': Could not resolve host: github.com
    gnutls_handshake() failed: The TLS connection was non-properly terminated.
EOF
    git config --global --unset http.proxy
    git config --global --unset https.proxy
}
