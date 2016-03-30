#***************************************************************************
#                                  _   _ ____  _
#  Project                     ___| | | |  _ \| |
#                             / __| | | | |_) | |
#                            | (__| |_| |  _ <| |___
#                             \___|\___/|_| \_\_____|
#
# Copyright (C) 1998 - 2014, Daniel Stenberg, <daniel@haxx.se>, et al.
#
# This software is licensed as described in the file COPYING, which
# you should have received as part of this distribution. The terms
# are also available at http://curl.haxx.se/docs/copyright.html.
#
# You may opt to use, copy, modify, merge, publish, distribute and/or sell
# copies of the Software, and permit persons to whom the Software is
# furnished to do so, under the terms of the COPYING file.
#
# This software is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY
# KIND, either express or implied.
#
###########################################################################
# cURL/libcurl CMake script
# by Tetetest and Sukender (Benoit Neil)

# TODO:
# The output .so file lacks the soname number which we currently have within the lib/Makefile.am file
# Add full (4 or 5 libs) SSL support
# Add INSTALL target (EXTRA_DIST variables in Makefile.am may be moved to Makefile.inc so that CMake/CPack is aware of what's to include).
# Add CTests(?)
# Check on all possible platforms
# Test with as many configurations possible (With or without any option)
# Create scripts that help keeping the CMake build system up to date (to reduce maintenance). According to Tetetest:
#  - lists of headers that 'configure' checks for;
#  - curl-specific tests (the ones that are in m4/curl-*.m4 files);
#  - (most obvious thing:) curl version numbers.
# Add documentation subproject
#
# To check:
# (From Daniel Stenberg) The cmake build selected to run gcc with -fPIC on my box while the plain configure script did not.
# (From Daniel Stenberg) The gcc command line use neither -g nor any -O options. As a developer, I also treasure our configure scripts's --enable-debug option that sets a long range of "picky" compiler options.
cmake_minimum_required(VERSION 2.8 FATAL_ERROR)
set(CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/CMake;${CMAKE_MODULE_PATH}")
include(Utilities)
include(Macros)

project( CURL C )

#message(WARNING "the curl cmake build system is poorly maintained. Be aware")

file (READ ${CURL_SOURCE_DIR}/include/curl/curlver.h CURL_VERSION_H_CONTENTS)
string (REGEX MATCH "#define LIBCURL_VERSION \"[^\"]*"
  CURL_VERSION ${CURL_VERSION_H_CONTENTS})
string (REGEX REPLACE "[^\"]+\"" "" CURL_VERSION ${CURL_VERSION})
string (REGEX MATCH "#define LIBCURL_VERSION_NUM 0x[0-9a-fA-F]+"
  CURL_VERSION_NUM ${CURL_VERSION_H_CONTENTS})
string (REGEX REPLACE "[^0]+0x" "" CURL_VERSION_NUM ${CURL_VERSION_NUM})

include_regular_expression("^.*$")    # Sukender: Is it necessary?

# Setup package meta-data
# SET(PACKAGE "curl")
message(STATUS "curl version=[${CURL_VERSION}]")
# SET(PACKAGE_TARNAME "curl")
# SET(PACKAGE_NAME "curl")
# SET(PACKAGE_VERSION "-")
# SET(PACKAGE_STRING "curl-")
# SET(PACKAGE_BUGREPORT "a suitable curl mailing list => http://curl.haxx.se/mail/")
set(OPERATING_SYSTEM "${CMAKE_SYSTEM_NAME}")
set(OS "\"${CMAKE_SYSTEM_NAME}\"")

include_directories(${CURL_BINARY_DIR}/include/curl ${CURL_SOURCE_DIR}/include)

option(BUILD_CURL_EXE "Set to ON to build cURL executable." OFF)
option(BUILD_CURL_TESTS "Set to ON to build cURL tests." OFF)
option(CURL_STATICLIB "Set to ON to build libcurl with static linking." ON)
option(ENABLE_ARES "Set to ON to enable c-ares support" OFF)
option(ENABLE_THREADED_RESOLVER "Set to ON to enable POSIX threaded DNS lookup" OFF)
# initialize CURL_LIBS
set(CURL_LIBS "")

if(ENABLE_THREADED_RESOLVER AND ENABLE_ARES)
  message(FATAL_ERROR "Options ENABLE_THREADED_RESOLVER and ENABLE_ARES are mutually exclusive")
endif()

if(ENABLE_ARES)
  set(USE_ARES 1)
  find_package(CARES REQUIRED)
  list(APPEND CURL_LIBS ${CARES_LIBRARY} )
  set(CURL_LIBS ${CURL_LIBS} ${CARES_LIBRARY})
endif()

option(BUILD_DASHBOARD_REPORTS "Set to ON to activate reporting of cURL builds here http://www.cdash.org/CDashPublic/index.php?project=CURL" OFF)
if(BUILD_DASHBOARD_REPORTS)
  #INCLUDE(Dart)
  include(CTest)
endif(BUILD_DASHBOARD_REPORTS)

if(MSVC)
  option(BUILD_RELEASE_DEBUG_DIRS "Set OFF to build each configuration to a separate directory" OFF)
  mark_as_advanced(BUILD_RELEASE_DEBUG_DIRS)
endif()

option(CURL_HIDDEN_SYMBOLS "Set to ON to hide libcurl internal symbols (=hide all symbols that aren't officially external)." ON)
mark_as_advanced(CURL_HIDDEN_SYMBOLS)

IF(WIN32)
  OPTION(CURL_WINDOWS_SSPI "Use windows libraries to allow NTLM authentication without openssl" ON)
  MARK_AS_ADVANCED(CURL_WINDOWS_SSPI)

  if (CURL_WINDOWS_SSPI)
    add_definitions(-DUSE_WINDOWS_SSPI -DUSE_SCHANNEL)
    set(SSL_ENABLED 1)
  endif()
ENDIF()

if(APPLE)
  # This is for both iOS and OSX

  find_library(CORE_FOUNDATION CoreFoundation)
  if(NOT CORE_FOUNDATION)
    message(FATAL_ERROR "Apple Core Foundation framework not found!")
  endif()
  list(APPEND CURL_LIBS ${CORE_FOUNDATION})

  find_library(SECURITY Security)
  if(NOT SECURITY)
    message(FATAL_ERROR "Apple Security framework not found!")
  endif()
  list(APPEND CURL_LIBS ${SECURITY})

  add_definitions(-DUSE_DARWINSSL)
  set(SSL_ENABLED 1)
endif()

option(HTTP_ONLY "disables all protocols except HTTP (This overrides all CURL_DISABLE_* options)" ON)
mark_as_advanced(HTTP_ONLY)
option(CURL_DISABLE_FTP "disables FTP" OFF)
mark_as_advanced(CURL_DISABLE_FTP)
option(CURL_DISABLE_LDAP "disables LDAP" OFF)
mark_as_advanced(CURL_DISABLE_LDAP)
option(CURL_DISABLE_TELNET "disables Telnet" OFF)
mark_as_advanced(CURL_DISABLE_TELNET)
option(CURL_DISABLE_DICT "disables DICT" OFF)
mark_as_advanced(CURL_DISABLE_DICT)
option(CURL_DISABLE_FILE "disables FILE" OFF)
mark_as_advanced(CURL_DISABLE_FILE)
option(CURL_DISABLE_TFTP "disables TFTP" OFF)
mark_as_advanced(CURL_DISABLE_TFTP)
option(CURL_DISABLE_HTTP "disables HTTP" OFF)
mark_as_advanced(CURL_DISABLE_HTTP)

option(CURL_DISABLE_LDAPS "to disable LDAPS" OFF)
mark_as_advanced(CURL_DISABLE_LDAPS)

option(CURL_DISABLE_RTSP "to disable RTSP" OFF)
mark_as_advanced(CURL_DISABLE_RTSP)
option(CURL_DISABLE_PROXY "to disable proxy" OFF)
mark_as_advanced(CURL_DISABLE_PROXY)
option(CURL_DISABLE_POP3 "to disable POP3" OFF)
mark_as_advanced(CURL_DISABLE_POP3)
option(CURL_DISABLE_IMAP "to disable IMAP" OFF)
mark_as_advanced(CURL_DISABLE_IMAP)
option(CURL_DISABLE_SMTP "to disable SMTP" OFF)
mark_as_advanced(CURL_DISABLE_SMTP)
option(CURL_DISABLE_GOPHER "to disable Gopher" OFF)
mark_as_advanced(CURL_DISABLE_GOPHER)

if(HTTP_ONLY)
  set(CURL_DISABLE_FTP ON)
  set(CURL_DISABLE_LDAP ON)
  set(CURL_DISABLE_LDAPS ON)
  set(CURL_DISABLE_TELNET ON)
  set(CURL_DISABLE_DICT ON)
  set(CURL_DISABLE_FILE ON)
  set(CURL_DISABLE_TFTP ON)
  set(CURL_DISABLE_RTSP ON)
  set(CURL_DISABLE_POP3 ON)
  set(CURL_DISABLE_IMAP ON)
  set(CURL_DISABLE_SMTP ON)
  set(CURL_DISABLE_GOPHER ON)
endif()

option(CURL_DISABLE_COOKIES "to disable cookies support" OFF)
mark_as_advanced(CURL_DISABLE_COOKIES)

option(CURL_DISABLE_CRYPTO_AUTH "to disable cryptographic authentication" OFF)
mark_as_advanced(CURL_DISABLE_CRYPTO_AUTH)
option(CURL_DISABLE_VERBOSE_STRINGS "to disable verbose strings" OFF)
mark_as_advanced(CURL_DISABLE_VERBOSE_STRINGS)
option(DISABLED_THREADSAFE "Set to explicitly specify we don't want to use thread-safe functions" OFF)
mark_as_advanced(DISABLED_THREADSAFE)
option(ENABLE_IPV6 "Define if you want to enable IPv6 support" ON)
mark_as_advanced(ENABLE_IPV6)
if(ENABLE_IPV6 AND NOT WIN32)
  if(APPLE)
    # This is for both iOS and OSX
    set(HAVE_SOCKADDR_IN6_SIN6_ADDR 1)
    set(HAVE_SOCKADDR_IN6_SIN6_SCOPE_ID 1)
  else()
    include(CheckStructHasMember)
    check_struct_has_member("struct sockaddr_in6" sin6_addr "netinet/in.h"
                            HAVE_SOCKADDR_IN6_SIN6_ADDR)
    check_struct_has_member("struct sockaddr_in6" sin6_scope_id "netinet/in.h"
                            HAVE_SOCKADDR_IN6_SIN6_SCOPE_ID)
  endif()
  if(NOT HAVE_SOCKADDR_IN6_SIN6_ADDR)
    message(WARNING "struct sockaddr_in6 not available, disabling IPv6 support")
    # Force the feature off as this name is used as guard macro...
    set(ENABLE_IPV6 OFF
        CACHE BOOL "Define if you want to enable IPv6 support" FORCE)
  endif()
endif()

option(ENABLE_MANUAL "to provide the built-in manual" OFF)
unset(USE_MANUAL CACHE) # TODO: cache NROFF/NROFF_MANOPT/USE_MANUAL vars?
if(ENABLE_MANUAL)
  find_program(NROFF NAMES gnroff nroff)
  if(NROFF)
    # Need a way to write to stdin, this will do
    file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/nroff-input.txt" "test")
    # Tests for a valid nroff option to generate a manpage
    foreach(_MANOPT "-man" "-mandoc")
      execute_process(COMMAND "${NROFF}" ${_MANOPT}
        OUTPUT_VARIABLE NROFF_MANOPT_OUTPUT
        INPUT_FILE "${CMAKE_CURRENT_BINARY_DIR}/nroff-input.txt"
        ERROR_QUIET)
      # Save the option if it was valid
      if(NROFF_MANOPT_OUTPUT)
        message("Found *nroff option: -- ${_MANOPT}")
        set(NROFF_MANOPT ${_MANOPT})
        set(USE_MANUAL 1)
        break()
      endif()
    endforeach()
    # No need for the temporary file
    file(REMOVE "${CMAKE_CURRENT_BINARY_DIR}/nroff-input.txt")
    if(NOT USE_MANUAL)
      message(WARNING "Found no *nroff option to get plaintext from man pages")
    endif()
  else()
    message(WARNING "Found no *nroff program")
  endif()
endif()

# We need ansi c-flags, especially on HP
set(CMAKE_C_FLAGS "${CMAKE_ANSI_CFLAGS} ${CMAKE_C_FLAGS}")
set(CMAKE_REQUIRED_FLAGS ${CMAKE_ANSI_CFLAGS})

# Disable warnings on Borland to avoid changing 3rd party code.
if(BORLAND)
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -w-")
endif(BORLAND)

# If we are on AIX, do the _ALL_SOURCE magic
if(${CMAKE_SYSTEM_NAME} MATCHES AIX)
  set(_ALL_SOURCE 1)
endif(${CMAKE_SYSTEM_NAME} MATCHES AIX)

# Include all the necessary files for macros
if(NOT APPLE)
  # This not used for either iOS or OSX
  include (CheckFunctionExists)
  include (CheckIncludeFile)
  include (CheckIncludeFiles)
  include (CheckLibraryExists)
  include (CheckSymbolExists)
  include (CheckTypeSize)
  include (CheckCSourceCompiles)
endif()

# On windows preload settings
if(WIN32)
  include(${CMAKE_CURRENT_SOURCE_DIR}/CMake/Platforms/WindowsCache.cmake)
endif(WIN32)

if(ENABLE_THREADED_RESOLVER)
  check_include_file_concat("pthread.h" HAVE_PTHREAD_H)
  if(HAVE_PTHREAD_H)
    set(CMAKE_THREAD_PREFER_PTHREAD 1)
    find_package(Threads)
    if(CMAKE_USE_PTHREADS_INIT)
      set(CURL_LIBS ${CURL_LIBS} ${CMAKE_THREAD_LIBS_INIT})
      set(USE_THREADS_POSIX 1)
    endif()
  endif()
endif()

# Check for all needed libraries
if(APPLE)
  # This is for both iOS and OSX
  set(HAVE_LIBDL OFF)
  set(HAVE_LIBSOCKET OFF)
  set(NOT_NEED_LIBNSL ON)
else()
  check_library_exists_concat("dl"     dlopen       HAVE_LIBDL)
  check_library_exists_concat("socket" connect      HAVE_LIBSOCKET)
  check_library_exists("c" gethostbyname "" NOT_NEED_LIBNSL)
endif()

# Yellowtab Zeta needs different libraries than BeOS 5.
if(BEOS)
  set(NOT_NEED_LIBNSL 1)
  check_library_exists_concat("bind" gethostbyname HAVE_LIBBIND)
  check_library_exists_concat("bnetapi" closesocket HAVE_LIBBNETAPI)
endif(BEOS)

if(NOT NOT_NEED_LIBNSL)
  check_library_exists_concat("nsl"    gethostbyname  HAVE_LIBNSL)
endif(NOT NOT_NEED_LIBNSL)

if(NOT APPLE)
  # This not used for both iOS or OSX
  check_function_exists(gethostname HAVE_GETHOSTNAME)
endif()

if(WIN32)
  check_library_exists_concat("ws2_32" getch        HAVE_LIBWS2_32)
  check_library_exists_concat("winmm"  getch        HAVE_LIBWINMM)
endif()

if (WIN32 OR APPLE)
  # Use platform spicific encryption on Windows, iOS, and OSX.
  option(CMAKE_USE_OPENSSL "Use OpenSSL code. Experimental" OFF)
else()
  option(CMAKE_USE_OPENSSL "Use OpenSSL code. Experimental" ON)
endif()
mark_as_advanced(CMAKE_USE_OPENSSL)

set(USE_SSLEAY OFF)
set(USE_OPENSSL OFF)
set(HAVE_LIBCRYPTO OFF)
set(HAVE_LIBSSL OFF)

if(CMAKE_USE_OPENSSL)
  find_package(OpenSSL)
  if(OPENSSL_FOUND)
    list(APPEND CURL_LIBS ${OPENSSL_LIBRARIES})
    set(USE_SSLEAY ON)
    set(USE_OPENSSL ON)
    set(HAVE_LIBCRYPTO ON)
    set(HAVE_LIBSSL ON)
    include_directories(${OPENSSL_INCLUDE_DIR})
    set(CMAKE_REQUIRED_INCLUDES ${OPENSSL_INCLUDE_DIR})
    if(APPLE)
      set(HAVE_OPENSSL_CRYPTO_H ON)
      set(HAVE_OPENSSL_ENGINE_H ON)
      set(HAVE_OPENSSL_ERR_H ON)
      set(HAVE_OPENSSL_PEM_H ON)
      set(HAVE_OPENSSL_PKCS12_H ON)
      set(HAVE_OPENSSL_RSA_H ON)
      set(HAVE_OPENSSL_SSL_H ON)
      set(HAVE_OPENSSL_X509_H ON)
      set(HAVE_OPENSSL_RAND_H ON)
    else()
      check_include_file_concat("openssl/crypto.h" HAVE_OPENSSL_CRYPTO_H)
      check_include_file_concat("openssl/engine.h" HAVE_OPENSSL_ENGINE_H)
      check_include_file_concat("openssl/err.h"    HAVE_OPENSSL_ERR_H)
      check_include_file_concat("openssl/pem.h"    HAVE_OPENSSL_PEM_H)
      check_include_file_concat("openssl/pkcs12.h" HAVE_OPENSSL_PKCS12_H)
      check_include_file_concat("openssl/rsa.h"    HAVE_OPENSSL_RSA_H)
      check_include_file_concat("openssl/ssl.h"    HAVE_OPENSSL_SSL_H)
      check_include_file_concat("openssl/x509.h"   HAVE_OPENSSL_X509_H)
      check_include_file_concat("openssl/rand.h"   HAVE_OPENSSL_RAND_H)
    endif()
  endif()
endif()

if(NOT CURL_DISABLE_LDAP)

  if(WIN32)
    option(CURL_LDAP_WIN "Use Windows LDAP implementation" ON)
    if(CURL_LDAP_WIN)
      check_library_exists("wldap32" cldap_open "" HAVE_WLDAP32)
      if(NOT HAVE_WLDAP32)
        set(CURL_LDAP_WIN OFF)
      endif()
    endif()
  endif()

  option(CMAKE_USE_OPENLDAP "Use OpenLDAP code." OFF)
  mark_as_advanced(CMAKE_USE_OPENLDAP)
  set(CMAKE_LDAP_LIB "ldap" CACHE STRING "Name or full path to ldap library")
  set(CMAKE_LBER_LIB "lber" CACHE STRING "Name or full path to lber library")

  if(CMAKE_USE_OPENLDAP AND CURL_LDAP_WIN)
    message(FATAL_ERROR "Cannot use CURL_LDAP_WIN and CMAKE_USE_OPENLDAP at the same time")
  endif()

  # Now that we know, we're not using windows LDAP...
  if(NOT CURL_LDAP_WIN)
    # Check for LDAP
    set(CMAKE_REQUIRED_LIBRARIES ${OPENSSL_LIBRARIES})
    check_library_exists_concat(${CMAKE_LDAP_LIB} ldap_init HAVE_LIBLDAP)
    check_library_exists_concat(${CMAKE_LBER_LIB} ber_init HAVE_LIBLBER)
  else()
    check_include_file_concat("winldap.h" HAVE_WINLDAP_H)
    check_include_file_concat("winber.h"  HAVE_WINBER_H)
  endif()

  set(CMAKE_LDAP_INCLUDE_DIR "" CACHE STRING "Path to LDAP include directory")
  if(CMAKE_LDAP_INCLUDE_DIR)
    set(CMAKE_REQUIRED_INCLUDES ${CMAKE_LDAP_INCLUDE_DIR})
  endif()
  check_include_file_concat("ldap.h"           HAVE_LDAP_H)
  check_include_file_concat("lber.h"           HAVE_LBER_H)

  if(NOT HAVE_LDAP_H)
    message(STATUS "LDAP_H not found CURL_DISABLE_LDAP set ON")
    set(CURL_DISABLE_LDAP ON CACHE BOOL "" FORCE)
  elseif(NOT HAVE_LIBLDAP)
    message(STATUS "LDAP library '${CMAKE_LDAP_LIB}' not found CURL_DISABLE_LDAP set ON")
    set(CURL_DISABLE_LDAP ON CACHE BOOL "" FORCE)
  else()
    if(CMAKE_USE_OPENLDAP)
      set(USE_OPENLDAP ON)
    endif()
    if(CMAKE_LDAP_INCLUDE_DIR)
      include_directories(${CMAKE_LDAP_INCLUDE_DIR})
    endif()
    set(NEED_LBER_H ON)
    set(_HEADER_LIST)
    if(HAVE_WINDOWS_H)
      list(APPEND _HEADER_LIST "windows.h")
    endif()
    if(HAVE_SYS_TYPES_H)
      list(APPEND _HEADER_LIST "sys/types.h")
    endif()
    list(APPEND _HEADER_LIST "ldap.h")

    set(_SRC_STRING "")
    foreach(_HEADER ${_HEADER_LIST})
      set(_INCLUDE_STRING "${_INCLUDE_STRING}#include <${_HEADER}>\n")
    endforeach()

    set(_SRC_STRING
      "
      ${_INCLUDE_STRING}
      int main(int argc, char ** argv)
      {
        BerValue *bvp = NULL;
        BerElement *bep = ber_init(bvp);
        ber_free(bep, 1);
        return 0;
      }"
    )
    set(CMAKE_REQUIRED_DEFINITIONS "-DLDAP_DEPRECATED=1" "-DWIN32_LEAN_AND_MEAN")
    list(APPEND CMAKE_REQUIRED_LIBRARIES ${CMAKE_LDAP_LIB})
    if(HAVE_LIBLBER)
      list(APPEND CMAKE_REQUIRED_LIBRARIES ${CMAKE_LBER_LIB})
    endif()
    check_c_source_compiles("${_SRC_STRING}" NOT_NEED_LBER_H)

    if(NOT_NEED_LBER_H)
      set(NEED_LBER_H OFF)
    else()
      set(CURL_TEST_DEFINES "${CURL_TEST_DEFINES} -DNEED_LBER_H")
    endif()
  endif()

endif()

# No ldap, no ldaps.
if(CURL_DISABLE_LDAP)
  if(NOT CURL_DISABLE_LDAPS)
    message(STATUS "LDAP needs to be enabled to support LDAPS")
    set(CURL_DISABLE_LDAPS ON CACHE BOOL "" FORCE)
  endif()
endif()

if(NOT CURL_DISABLE_LDAPS)
  check_include_file_concat("ldap_ssl.h" HAVE_LDAP_SSL_H)
  check_include_file_concat("ldapssl.h"  HAVE_LDAPSSL_H)
endif()

if(NOT APPLE)
  # This not used for either iOS or OSX

  # Check for idn
  check_library_exists_concat("idn" idna_to_ascii_lz HAVE_LIBIDN)

  # Check for symbol dlopen (same as HAVE_LIBDL)
  check_library_exists("${CURL_LIBS}" dlopen "" HAVE_DLOPEN)
endif()

option(CURL_ZLIB "Set to ON to enable building cURL with zlib support." ON)
set(HAVE_LIBZ OFF)
set(HAVE_ZLIB_H OFF)
set(HAVE_ZLIB OFF)
if(CURL_ZLIB)
  find_package(ZLIB QUIET)
  if(ZLIB_FOUND)
    set(HAVE_ZLIB_H ON)
    set(HAVE_ZLIB ON)
    set(HAVE_LIBZ ON)
    list(APPEND CURL_LIBS ${ZLIB_LIBRARIES})
    include_directories(${ZLIB_INCLUDE_DIRS})
  endif()
endif()

#libSSH2
option(CMAKE_USE_LIBSSH2 "Use libSSH2" OFF)
mark_as_advanced(CMAKE_USE_LIBSSH2)
set(USE_LIBSSH2 OFF)
set(HAVE_LIBSSH2 OFF)
set(HAVE_LIBSSH2_H OFF)

if(CMAKE_USE_LIBSSH2)
  find_package(LibSSH2)
  if(LIBSSH2_FOUND)
    list(APPEND CURL_LIBS ${LIBSSH2_LIBRARY})
    set(CMAKE_REQUIRED_LIBRARIES ${LIBSSH2_LIBRARY})
    set(CMAKE_REQUIRED_INCLUDES "${LIBSSH2_INCLUDE_DIR}")
    include_directories("${LIBSSH2_INCLUDE_DIR}")
    set(HAVE_LIBSSH2 ON)
    set(USE_LIBSSH2 ON)

    # find_package has already found the headers
    set(HAVE_LIBSSH2_H ON)
    set(CURL_INCLUDES ${CURL_INCLUDES} "${LIBSSH2_INCLUDE_DIR}/libssh2.h")
    set(CURL_TEST_DEFINES "${CURL_TEST_DEFINES} -DHAVE_LIBSSH2_H")

    # now check for specific libssh2 symbols as they were added in different versions
    set(CMAKE_EXTRA_INCLUDE_FILES "libssh2.h")
    check_function_exists(libssh2_version           HAVE_LIBSSH2_VERSION)
    check_function_exists(libssh2_init              HAVE_LIBSSH2_INIT)
    check_function_exists(libssh2_exit              HAVE_LIBSSH2_EXIT)
    check_function_exists(libssh2_scp_send64        HAVE_LIBSSH2_SCP_SEND64)
    check_function_exists(libssh2_session_handshake HAVE_LIBSSH2_SESSION_HANDSHAKE)
    set(CMAKE_EXTRA_INCLUDE_FILES "")

  endif(LIBSSH2_FOUND)
endif(CMAKE_USE_LIBSSH2)

option(CMAKE_USE_GSSAPI "Use GSSAPI implementation (right now only Heimdal is supported with CMake build)" OFF)
mark_as_advanced(CMAKE_USE_GSSAPI)

if(CMAKE_USE_GSSAPI)
  find_package(GSS)

  set(HAVE_GSS_API ${GSS_FOUND})
  if(GSS_FOUND)

    message(STATUS "Found ${GSS_FLAVOUR} GSSAPI version: \"${GSS_VERSION}\"")

    set(CMAKE_REQUIRED_INCLUDES ${GSS_INCLUDE_DIR})
    check_include_file_concat("gssapi/gssapi.h"  HAVE_GSSAPI_GSSAPI_H)
    check_include_file_concat("gssapi/gssapi_generic.h" HAVE_GSSAPI_GSSAPI_GENERIC_H)
    check_include_file_concat("gssapi/gssapi_krb5.h" HAVE_GSSAPI_GSSAPI_KRB5_H)

    if(GSS_FLAVOUR STREQUAL "Heimdal")
      set(HAVE_GSSHEIMDAL ON)
    else() # MIT
      set(HAVE_GSSMIT ON)
      set(_INCLUDE_LIST "")
      if(HAVE_GSSAPI_GSSAPI_H)
        list(APPEND _INCLUDE_LIST "gssapi/gssapi.h")
      endif()
      if(HAVE_GSSAPI_GSSAPI_GENERIC_H)
        list(APPEND _INCLUDE_LIST "gssapi/gssapi_generic.h")
      endif()
      if(HAVE_GSSAPI_GSSAPI_KRB5_H)
        list(APPEND _INCLUDE_LIST "gssapi/gssapi_krb5.h")
      endif()

      string(REPLACE ";" " " _COMPILER_FLAGS_STR "${GSS_COMPILER_FLAGS}")
      string(REPLACE ";" " " _LINKER_FLAGS_STR "${GSS_LINKER_FLAGS}")

      foreach(_dir ${GSS_LINK_DIRECTORIES})
        set(_LINKER_FLAGS_STR "${_LINKER_FLAGS_STR} -L\"${_dir}\"")
      endforeach()

      set(CMAKE_REQUIRED_FLAGS "${_COMPILER_FLAGS_STR} ${_LINKER_FLAGS_STR}")
      set(CMAKE_REQUIRED_LIBRARIES ${GSS_LIBRARIES})
      check_symbol_exists("GSS_C_NT_HOSTBASED_SERVICE" ${_INCLUDE_LIST} HAVE_GSS_C_NT_HOSTBASED_SERVICE)
      if(NOT HAVE_GSS_C_NT_HOSTBASED_SERVICE)
        set(HAVE_OLD_GSSMIT ON)
      endif()

    endif()

    include_directories(${GSS_INCLUDE_DIR})
    link_directories(${GSS_LINK_DIRECTORIES})
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${GSS_COMPILER_FLAGS}")
    set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} ${GSS_LINKER_FLAGS}")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${GSS_LINKER_FLAGS}")
    list(APPEND CURL_LIBS ${GSS_LIBRARIES})

  else()
    message(WARNING "GSSAPI support has been requested but no supporting libraries found. Skipping.")
  endif()
endif()

option(ENABLE_UNIX_SOCKETS "Define if you want Unix domain sockets support" ON)
if(ENABLE_UNIX_SOCKETS)
  if(APPLE)
    # This is for both iOS and OSX
    set(USE_UNIX_SOCKETS ON)
  else()
    include(CheckStructHasMember)
    check_struct_has_member("struct sockaddr_un" sun_path "sys/un.h" USE_UNIX_SOCKETS)
  endif()
else()
  unset(USE_UNIX_SOCKETS CACHE)
endif()

# Check for header files
if(NOT UNIX)
  check_include_file_concat("ws2tcpip.h"     HAVE_WS2TCPIP_H)
  check_include_file_concat("winsock2.h"     HAVE_WINSOCK2_H)
  check_include_file_concat("windows.h"      HAVE_WINDOWS_H)
  check_include_file_concat("winsock.h"      HAVE_WINSOCK_H)
endif(NOT UNIX)

if(APPLE)
  # This is for both iOS and OSX
  set(HAVE_INTTYPES_H ON)
  set(HAVE_SYS_FILIO_H ON)
  set(HAVE_SYS_IOCTL_H ON)
  set(HAVE_SYS_PARAM_H ON)
  set(HAVE_SYS_POLL_H ON)
  set(HAVE_SYS_RESOURCE_H ON)
  set(HAVE_SYS_SELECT_H ON)
  set(HAVE_SYS_SOCKET_H ON)
  set(HAVE_SYS_SOCKIO_H ON)
  set(HAVE_SYS_STAT_H ON)
  set(HAVE_SYS_TIME_H ON)
  set(HAVE_SYS_TYPES_H ON)
  set(HAVE_SYS_UIO_H ON)
  set(HAVE_SYS_UN_H ON)
  set(HAVE_SYS_UTIME_H OFF)
  set(HAVE_ALLOCA_H ON)
  set(HAVE_ARPA_INET_H ON)
  set(HAVE_ARPA_TFTP_H ON)
  set(HAVE_ASSERT_H ON)
  set(HAVE_CRYPTO_H OFF)
  set(HAVE_DES_H OFF)
  set(HAVE_ERR_H ON)
  set(HAVE_ERRNO_H ON)
  set(HAVE_FCNTL_H ON)
  set(HAVE_IDN_FREE_H OFF)
  set(HAVE_IFADDRS_H ON)
  set(HAVE_IO_H OFF)
  set(HAVE_KRB_H OFF)
  set(HAVE_LIBGEN_H ON)
  set(HAVE_LIMITS_H ON)
  set(HAVE_LOCALE_H ON)
  set(HAVE_NET_IF_H ON)
  set(HAVE_NETDB_H ON)
  set(HAVE_NETINET_IN_H ON)
  set(HAVE_NETINET_TCP_H ON)

  set(HAVE_PEM_H OFF)
  set(HAVE_POLL_H ON)
  set(HAVE_PWD_H ON)
  set(HAVE_RSA_H OFF)
  set(HAVE_SETJMP_H ON)
  set(HAVE_SGTTY_H ON)
  set(HAVE_SIGNAL_H ON)
  set(HAVE_SSL_H OFF)
  set(HAVE_STDBOOL_H ON)
  set(HAVE_STDINT_H ON)
  set(HAVE_STDIO_H ON)
  set(HAVE_STDLIB_H ON)
  set(HAVE_STRING_H ON)
  set(HAVE_STRINGS_H ON)
  set(HAVE_STROPTS_H OFF)
  set(HAVE_TERMIO_H OFF)
  set(HAVE_TERMIOS_H ON)
  set(HAVE_TIME_H ON)
  set(HAVE_TLD_H OFF)
  set(HAVE_UNISTD_H ON)
  set(HAVE_UTIME_H ON)
  set(HAVE_X509_H OFF)

  set(HAVE_PROCESS_H OFF)
  set(HAVE_STDDEF_H ON)
  set(HAVE_DLFCN_H ON)
  set(HAVE_MALLOC_H OFF)
  set(HAVE_MEMORY_H ON)
  set(HAVE_NETINET_IF_ETHER_H ON)
  set(HAVE_STDINT_H ON)
  set(HAVE_SOCKIO_H ON)
  set(HAVE_SYS_UTSNAME_H ON)
  set(HAVE_IDNA_H ON)



  set(SIZEOF_SIZE_T 8)
  set(SIZEOF_SSIZE_T 8)
  set(HAVE_SIZEOF_SSIZE_T ON)
  set(SIZEOF_LONG_LONG 8)
  set(HAVE_SIZEOF_LONG_LONG ON)
  set(SIZEOF_LONG 8)
  set(SIZEOF_SHORT 2)
  set(SIZEOF_INT 4)
  set(SIZEOF___INT64 8)
  set(SIZEOF_LONG_DOUBLE 8)
  set(SIZEOF_TIME_T 8)
else(APPLE)
  check_include_file_concat("inttypes.h"       HAVE_INTTYPES_H)
  check_include_file_concat("sys/filio.h"      HAVE_SYS_FILIO_H)
  check_include_file_concat("sys/ioctl.h"      HAVE_SYS_IOCTL_H)
  check_include_file_concat("sys/param.h"      HAVE_SYS_PARAM_H)
  check_include_file_concat("sys/poll.h"       HAVE_SYS_POLL_H)
  check_include_file_concat("sys/resource.h"   HAVE_SYS_RESOURCE_H)
  check_include_file_concat("sys/select.h"     HAVE_SYS_SELECT_H)
  check_include_file_concat("sys/socket.h"     HAVE_SYS_SOCKET_H)
  check_include_file_concat("sys/sockio.h"     HAVE_SYS_SOCKIO_H)
  check_include_file_concat("sys/stat.h"       HAVE_SYS_STAT_H)
  check_include_file_concat("sys/time.h"       HAVE_SYS_TIME_H)
  check_include_file_concat("sys/types.h"      HAVE_SYS_TYPES_H)
  check_include_file_concat("sys/uio.h"        HAVE_SYS_UIO_H)
  check_include_file_concat("sys/un.h"         HAVE_SYS_UN_H)
  check_include_file_concat("sys/utime.h"      HAVE_SYS_UTIME_H)
  check_include_file_concat("alloca.h"         HAVE_ALLOCA_H)
  check_include_file_concat("arpa/inet.h"      HAVE_ARPA_INET_H)
  check_include_file_concat("arpa/tftp.h"      HAVE_ARPA_TFTP_H)
  check_include_file_concat("assert.h"         HAVE_ASSERT_H)
  check_include_file_concat("crypto.h"         HAVE_CRYPTO_H)
  check_include_file_concat("des.h"            HAVE_DES_H)
  check_include_file_concat("err.h"            HAVE_ERR_H)
  check_include_file_concat("errno.h"          HAVE_ERRNO_H)
  check_include_file_concat("fcntl.h"          HAVE_FCNTL_H)
  check_include_file_concat("idn-free.h"       HAVE_IDN_FREE_H)
  check_include_file_concat("ifaddrs.h"        HAVE_IFADDRS_H)
  check_include_file_concat("io.h"             HAVE_IO_H)
  check_include_file_concat("krb.h"            HAVE_KRB_H)
  check_include_file_concat("libgen.h"         HAVE_LIBGEN_H)
  check_include_file_concat("limits.h"         HAVE_LIMITS_H)
  check_include_file_concat("locale.h"         HAVE_LOCALE_H)
  check_include_file_concat("net/if.h"         HAVE_NET_IF_H)
  check_include_file_concat("netdb.h"          HAVE_NETDB_H)
  check_include_file_concat("netinet/in.h"     HAVE_NETINET_IN_H)
  check_include_file_concat("netinet/tcp.h"    HAVE_NETINET_TCP_H)

  check_include_file_concat("pem.h"            HAVE_PEM_H)
  check_include_file_concat("poll.h"           HAVE_POLL_H)
  check_include_file_concat("pwd.h"            HAVE_PWD_H)
  check_include_file_concat("rsa.h"            HAVE_RSA_H)
  check_include_file_concat("setjmp.h"         HAVE_SETJMP_H)
  check_include_file_concat("sgtty.h"          HAVE_SGTTY_H)
  check_include_file_concat("signal.h"         HAVE_SIGNAL_H)
  check_include_file_concat("ssl.h"            HAVE_SSL_H)
  check_include_file_concat("stdbool.h"        HAVE_STDBOOL_H)
  check_include_file_concat("stdint.h"         HAVE_STDINT_H)
  check_include_file_concat("stdio.h"          HAVE_STDIO_H)
  check_include_file_concat("stdlib.h"         HAVE_STDLIB_H)
  check_include_file_concat("string.h"         HAVE_STRING_H)
  check_include_file_concat("strings.h"        HAVE_STRINGS_H)
  check_include_file_concat("stropts.h"        HAVE_STROPTS_H)
  check_include_file_concat("termio.h"         HAVE_TERMIO_H)
  check_include_file_concat("termios.h"        HAVE_TERMIOS_H)
  check_include_file_concat("time.h"           HAVE_TIME_H)
  check_include_file_concat("tld.h"            HAVE_TLD_H)
  check_include_file_concat("unistd.h"         HAVE_UNISTD_H)
  check_include_file_concat("utime.h"          HAVE_UTIME_H)
  check_include_file_concat("x509.h"           HAVE_X509_H)

  check_include_file_concat("process.h"        HAVE_PROCESS_H)
  check_include_file_concat("stddef.h"         HAVE_STDDEF_H)
  check_include_file_concat("dlfcn.h"          HAVE_DLFCN_H)
  check_include_file_concat("malloc.h"         HAVE_MALLOC_H)
  check_include_file_concat("memory.h"         HAVE_MEMORY_H)
  check_include_file_concat("netinet/if_ether.h" HAVE_NETINET_IF_ETHER_H)
  check_include_file_concat("stdint.h"        HAVE_STDINT_H)
  check_include_file_concat("sockio.h"        HAVE_SOCKIO_H)
  check_include_file_concat("sys/utsname.h"   HAVE_SYS_UTSNAME_H)
  check_include_file_concat("idna.h"          HAVE_IDNA_H)



  check_type_size(size_t  SIZEOF_SIZE_T)
  check_type_size(ssize_t  SIZEOF_SSIZE_T)
  check_type_size("long long"  SIZEOF_LONG_LONG)
  check_type_size("long"  SIZEOF_LONG)
  check_type_size("short"  SIZEOF_SHORT)
  check_type_size("int"  SIZEOF_INT)
  check_type_size("__int64"  SIZEOF___INT64)
  check_type_size("long double"  SIZEOF_LONG_DOUBLE)
  check_type_size("time_t"  SIZEOF_TIME_T)
endif(APPLE)


if(NOT HAVE_SIZEOF_SSIZE_T)
  if(SIZEOF_LONG EQUAL SIZEOF_SIZE_T)
    set(ssize_t long)
  endif(SIZEOF_LONG EQUAL SIZEOF_SIZE_T)
  if(NOT ssize_t AND SIZEOF___INT64 EQUAL SIZEOF_SIZE_T)
    set(ssize_t __int64)
  endif(NOT ssize_t AND SIZEOF___INT64 EQUAL SIZEOF_SIZE_T)
endif(NOT HAVE_SIZEOF_SSIZE_T)

# Different sizeofs, etc.

#    define CURL_SIZEOF_LONG        4
#    define CURL_TYPEOF_CURL_OFF_T  long long
#    define CURL_FORMAT_CURL_OFF_T  "lld"
#    define CURL_FORMAT_CURL_OFF_TU "llu"
#    define CURL_FORMAT_OFF_T       "%lld"
#    define CURL_SIZEOF_CURL_OFF_T  8
#    define CURL_SUFFIX_CURL_OFF_T  LL
#    define CURL_SUFFIX_CURL_OFF_TU ULL

set(CURL_SIZEOF_LONG ${SIZEOF_LONG})

if(SIZEOF_LONG EQUAL 8)
  set(CURL_TYPEOF_CURL_OFF_T long)
  set(CURL_SIZEOF_CURL_OFF_T 8)
  set(CURL_FORMAT_CURL_OFF_T "ld")
  set(CURL_FORMAT_CURL_OFF_TU "lu")
  set(CURL_FORMAT_OFF_T "%ld")
  set(CURL_SUFFIX_CURL_OFF_T L)
  set(CURL_SUFFIX_CURL_OFF_TU UL)
endif(SIZEOF_LONG EQUAL 8)

if(SIZEOF_LONG_LONG EQUAL 8)
  set(CURL_TYPEOF_CURL_OFF_T "long long")
  set(CURL_SIZEOF_CURL_OFF_T 8)
  set(CURL_FORMAT_CURL_OFF_T "lld")
  set(CURL_FORMAT_CURL_OFF_TU "llu")
  set(CURL_FORMAT_OFF_T "%lld")
  set(CURL_SUFFIX_CURL_OFF_T LL)
  set(CURL_SUFFIX_CURL_OFF_TU ULL)
endif(SIZEOF_LONG_LONG EQUAL 8)

if(NOT CURL_TYPEOF_CURL_OFF_T)
  set(CURL_TYPEOF_CURL_OFF_T ${ssize_t})
  set(CURL_SIZEOF_CURL_OFF_T ${SIZEOF_SSIZE_T})
  # TODO: need adjustment here.
  set(CURL_FORMAT_CURL_OFF_T "ld")
  set(CURL_FORMAT_CURL_OFF_TU "lu")
  set(CURL_FORMAT_OFF_T "%ld")
  set(CURL_SUFFIX_CURL_OFF_T L)
  set(CURL_SUFFIX_CURL_OFF_TU LU)
endif(NOT CURL_TYPEOF_CURL_OFF_T)

if(HAVE_SIZEOF_LONG_LONG)
  set(HAVE_LONGLONG 1)
  set(HAVE_LL 1)
endif(HAVE_SIZEOF_LONG_LONG)

find_file(RANDOM_FILE urandom /dev)
mark_as_advanced(RANDOM_FILE)

# Check for some functions that are used
if(HAVE_LIBWS2_32)
  set(CMAKE_REQUIRED_LIBRARIES ws2_32)
elseif(HAVE_LIBSOCKET)
  set(CMAKE_REQUIRED_LIBRARIES socket)
endif()

if(APPLE)
  # This is for both iOS and OSX
  set(HAVE_BASENAME ON)
  set(HAVE_SOCKET ON)
  set(HAVE_POLL ON)
  set(HAVE_SELECT ON)
  set(HAVE_STRDUP ON)
  set(HAVE_STRSTR ON)
  set(HAVE_STRTOK_R ON)
  set(HAVE_STRFTIME ON)
  set(HAVE_UNAME ON)
  set(HAVE_STRCASECMP ON)
  set(HAVE_STRICMP OFF)
  set(HAVE_STRCMPI OFF)
  set(HAVE_STRNCMPI OFF)
  set(HAVE_ALARM ON)
  if(NOT HAVE_STRNCMPI)
    set(HAVE_STRCMPI)
  endif(NOT HAVE_STRNCMPI)
  set(HAVE_GETHOSTBYADDR ON)
  set(HAVE_GETHOSTBYADDR_R OFF)
  set(HAVE_GETTIMEOFDAY ON)
  set(HAVE_INET_ADDR ON)
  set(HAVE_INET_NTOA OFF)
  set(HAVE_INET_NTOA_R OFF)
  set(HAVE_TCSETATTR OFF)
  set(HAVE_TCGETATTR OFF)
  set(HAVE_PERROR ON)
  set(HAVE_CLOSESOCKET OFF)
  set(HAVE_SETVBUF OFF)
  set(HAVE_SIGSETJMP ON)
  set(HAVE_GETPASS_R OFF)
  set(HAVE_STRLCAT ON)
  set(HAVE_GETPWUID ON)
  set(HAVE_GETEUID ON)
  set(HAVE_UTIME OFF)
  if(CMAKE_USE_OPENSSL)
    set(HAVE_RAND_STATUS OFF)
    set(HAVE_RAND_SCREEN OFF)
    set(HAVE_RAND_EGD OFF)
    set(HAVE_CRYPTO_CLEANUP_ALL_EX_DATA OFF)
    if(HAVE_LIBCRYPTO AND HAVE_LIBSSL)
      set(USE_OPENSSL 1)
      set(USE_SSLEAY 1)
    endif(HAVE_LIBCRYPTO AND HAVE_LIBSSL)
  endif(CMAKE_USE_OPENSSL)
  set(HAVE_GMTIME_R ON)
  set(HAVE_LOCALTIME_R ON)

  set(HAVE_GETHOSTBYNAME ON)
  set(HAVE_GETHOSTBYNAME_R OFF)

  set(HAVE_SIGNAL_FUNC ON)
  set(HAVE_SIGNAL_MACRO ON)
  if(HAVE_SIGNAL_FUNC AND HAVE_SIGNAL_MACRO)
    set(HAVE_SIGNAL 1)
  endif(HAVE_SIGNAL_FUNC AND HAVE_SIGNAL_MACRO)
  set(HAVE_UNAME ON)
  set(HAVE_STRTOLL ON)
  set(HAVE__STRTOI64 ON)
  set(HAVE_STRERROR_R ON)
  set(HAVE_SIGINTERRUPT ON)
  set(HAVE_PERROR ON)
  set(HAVE_FORK ON)
  set(HAVE_GETADDRINFO ON)
  set(HAVE_FREEADDRINFO ON)
  set(HAVE_FREEIFADDRS ON)
  set(HAVE_PIPE ON)
  set(HAVE_FTRUNCATE ON)
  set(HAVE_GETPROTOBYNAME ON)
  set(HAVE_GETRLIMIT ON)
  set(HAVE_IDN_FREE OFF)
  set(HAVE_IDNA_STRERROR OFF)
  set(HAVE_TLD_STRERROR OFF)
  set(HAVE_SETLOCALE ON)
  set(HAVE_SETRLIMIT ON)
  set(HAVE_FCNTL ON)
  set(HAVE_IOCTL ON)
  set(HAVE_SETSOCKOPT ON)

  # symbol exists in win32, but function does not.
  set(HAVE_INET_PTON ON)

  # sigaction and sigsetjmp are special. Use special mechanism for
  # detecting those, but only if previous attempt failed.
  if(HAVE_SIGNAL_H)
    set(HAVE_SIGACTION ON)
  endif(HAVE_SIGNAL_H)

  if(NOT HAVE_SIGSETJMP)
    if(HAVE_SETJMP_H)
      set(HAVE_MACRO_SIGSETJMP ON)
      if(HAVE_MACRO_SIGSETJMP)
        set(HAVE_SIGSETJMP 1)
      endif(HAVE_MACRO_SIGSETJMP)
    endif(HAVE_SETJMP_H)
  endif(NOT HAVE_SIGSETJMP)

else(APPLE)
  check_symbol_exists(basename      "${CURL_INCLUDES}" HAVE_BASENAME)
  check_symbol_exists(socket        "${CURL_INCLUDES}" HAVE_SOCKET)
  check_symbol_exists(poll          "${CURL_INCLUDES}" HAVE_POLL)
  check_symbol_exists(select        "${CURL_INCLUDES}" HAVE_SELECT)
  check_symbol_exists(strdup        "${CURL_INCLUDES}" HAVE_STRDUP)
  check_symbol_exists(strstr        "${CURL_INCLUDES}" HAVE_STRSTR)
  check_symbol_exists(strtok_r      "${CURL_INCLUDES}" HAVE_STRTOK_R)
  check_symbol_exists(strftime      "${CURL_INCLUDES}" HAVE_STRFTIME)
  check_symbol_exists(uname         "${CURL_INCLUDES}" HAVE_UNAME)
  check_symbol_exists(strcasecmp    "${CURL_INCLUDES}" HAVE_STRCASECMP)
  check_symbol_exists(stricmp       "${CURL_INCLUDES}" HAVE_STRICMP)
  check_symbol_exists(strcmpi       "${CURL_INCLUDES}" HAVE_STRCMPI)
  check_symbol_exists(strncmpi      "${CURL_INCLUDES}" HAVE_STRNCMPI)
  check_symbol_exists(alarm         "${CURL_INCLUDES}" HAVE_ALARM)
  if(NOT HAVE_STRNCMPI)
    set(HAVE_STRCMPI)
  endif(NOT HAVE_STRNCMPI)
  check_symbol_exists(gethostbyaddr "${CURL_INCLUDES}" HAVE_GETHOSTBYADDR)
  check_symbol_exists(gethostbyaddr_r "${CURL_INCLUDES}" HAVE_GETHOSTBYADDR_R)
  check_symbol_exists(gettimeofday  "${CURL_INCLUDES}" HAVE_GETTIMEOFDAY)
  check_symbol_exists(inet_addr     "${CURL_INCLUDES}" HAVE_INET_ADDR)
  check_symbol_exists(inet_ntoa     "${CURL_INCLUDES}" HAVE_INET_NTOA)
  check_symbol_exists(inet_ntoa_r   "${CURL_INCLUDES}" HAVE_INET_NTOA_R)
  check_symbol_exists(tcsetattr     "${CURL_INCLUDES}" HAVE_TCSETATTR)
  check_symbol_exists(tcgetattr     "${CURL_INCLUDES}" HAVE_TCGETATTR)
  check_symbol_exists(perror        "${CURL_INCLUDES}" HAVE_PERROR)
  check_symbol_exists(closesocket   "${CURL_INCLUDES}" HAVE_CLOSESOCKET)
  check_symbol_exists(setvbuf       "${CURL_INCLUDES}" HAVE_SETVBUF)
  check_symbol_exists(sigsetjmp     "${CURL_INCLUDES}" HAVE_SIGSETJMP)
  check_symbol_exists(getpass_r     "${CURL_INCLUDES}" HAVE_GETPASS_R)
  check_symbol_exists(strlcat       "${CURL_INCLUDES}" HAVE_STRLCAT)
  check_symbol_exists(getpwuid      "${CURL_INCLUDES}" HAVE_GETPWUID)
  check_symbol_exists(geteuid       "${CURL_INCLUDES}" HAVE_GETEUID)
  check_symbol_exists(utime         "${CURL_INCLUDES}" HAVE_UTIME)
  if(CMAKE_USE_OPENSSL)
    check_symbol_exists(RAND_status   "${CURL_INCLUDES}" HAVE_RAND_STATUS)
    check_symbol_exists(RAND_screen   "${CURL_INCLUDES}" HAVE_RAND_SCREEN)
    check_symbol_exists(RAND_egd      "${CURL_INCLUDES}" HAVE_RAND_EGD)
    check_symbol_exists(CRYPTO_cleanup_all_ex_data "${CURL_INCLUDES}"
      HAVE_CRYPTO_CLEANUP_ALL_EX_DATA)
    if(HAVE_LIBCRYPTO AND HAVE_LIBSSL)
      set(USE_OPENSSL 1)
      set(USE_SSLEAY 1)
    endif(HAVE_LIBCRYPTO AND HAVE_LIBSSL)
  endif(CMAKE_USE_OPENSSL)
  check_symbol_exists(gmtime_r      "${CURL_INCLUDES}" HAVE_GMTIME_R)
  check_symbol_exists(localtime_r   "${CURL_INCLUDES}" HAVE_LOCALTIME_R)

  check_symbol_exists(gethostbyname   "${CURL_INCLUDES}" HAVE_GETHOSTBYNAME)
  check_symbol_exists(gethostbyname_r "${CURL_INCLUDES}" HAVE_GETHOSTBYNAME_R)

  check_symbol_exists(signal        "${CURL_INCLUDES}" HAVE_SIGNAL_FUNC)
  check_symbol_exists(SIGALRM       "${CURL_INCLUDES}" HAVE_SIGNAL_MACRO)
  if(HAVE_SIGNAL_FUNC AND HAVE_SIGNAL_MACRO)
    set(HAVE_SIGNAL 1)
  endif(HAVE_SIGNAL_FUNC AND HAVE_SIGNAL_MACRO)
  check_symbol_exists(uname          "${CURL_INCLUDES}" HAVE_UNAME)
  check_symbol_exists(strtoll        "${CURL_INCLUDES}" HAVE_STRTOLL)
  check_symbol_exists(_strtoi64      "${CURL_INCLUDES}" HAVE__STRTOI64)
  check_symbol_exists(strerror_r     "${CURL_INCLUDES}" HAVE_STRERROR_R)
  check_symbol_exists(siginterrupt   "${CURL_INCLUDES}" HAVE_SIGINTERRUPT)
  check_symbol_exists(perror         "${CURL_INCLUDES}" HAVE_PERROR)
  check_symbol_exists(fork           "${CURL_INCLUDES}" HAVE_FORK)
  check_symbol_exists(getaddrinfo    "${CURL_INCLUDES}" HAVE_GETADDRINFO)
  check_symbol_exists(freeaddrinfo   "${CURL_INCLUDES}" HAVE_FREEADDRINFO)
  check_symbol_exists(freeifaddrs    "${CURL_INCLUDES}" HAVE_FREEIFADDRS)
  check_symbol_exists(pipe           "${CURL_INCLUDES}" HAVE_PIPE)
  check_symbol_exists(ftruncate      "${CURL_INCLUDES}" HAVE_FTRUNCATE)
  check_symbol_exists(getprotobyname "${CURL_INCLUDES}" HAVE_GETPROTOBYNAME)
  check_symbol_exists(getrlimit      "${CURL_INCLUDES}" HAVE_GETRLIMIT)
  check_symbol_exists(idn_free       "${CURL_INCLUDES}" HAVE_IDN_FREE)
  check_symbol_exists(idna_strerror  "${CURL_INCLUDES}" HAVE_IDNA_STRERROR)
  check_symbol_exists(tld_strerror   "${CURL_INCLUDES}" HAVE_TLD_STRERROR)
  check_symbol_exists(setlocale      "${CURL_INCLUDES}" HAVE_SETLOCALE)
  check_symbol_exists(setrlimit      "${CURL_INCLUDES}" HAVE_SETRLIMIT)
  check_symbol_exists(fcntl          "${CURL_INCLUDES}" HAVE_FCNTL)
  check_symbol_exists(ioctl          "${CURL_INCLUDES}" HAVE_IOCTL)
  check_symbol_exists(setsockopt     "${CURL_INCLUDES}" HAVE_SETSOCKOPT)

  # symbol exists in win32, but function does not.
  check_function_exists(inet_pton HAVE_INET_PTON)

  # sigaction and sigsetjmp are special. Use special mechanism for
  # detecting those, but only if previous attempt failed.
  if(HAVE_SIGNAL_H)
    check_symbol_exists(sigaction "signal.h" HAVE_SIGACTION)
  endif(HAVE_SIGNAL_H)

  if(NOT HAVE_SIGSETJMP)
    if(HAVE_SETJMP_H)
      check_symbol_exists(sigsetjmp "setjmp.h" HAVE_MACRO_SIGSETJMP)
      if(HAVE_MACRO_SIGSETJMP)
        set(HAVE_SIGSETJMP 1)
      endif(HAVE_MACRO_SIGSETJMP)
    endif(HAVE_SETJMP_H)
  endif(NOT HAVE_SIGSETJMP)
endif(APPLE)

# If there is no stricmp(), do not allow LDAP to parse URLs
if(NOT HAVE_STRICMP)
  set(HAVE_LDAP_URL_PARSE 1)
endif(NOT HAVE_STRICMP)


# See if we're being cross compiled, so make sure that tests that need to
# run already have results filled. Also fill results if we don't want to
# run the checks that would fill them, such as on OSX.
if(CMAKE_CROSSCOMPILING OR APPLE)
  SET(HAVE_GLIBC_STRERROR_R "" CACHE STRING "Result from TRY_RUN" FORCE)
  SET(HAVE_GLIBC_STRERROR_R__TRYRUN_OUTPUT "" CACHE STRING "Output from TRY_RUN" FORCE)
  SET(HAVE_POSIX_STRERROR_R 1 CACHE STRING "Result from TRY_RUN" FORCE)
  SET(HAVE_POSIX_STRERROR_R__TRYRUN_OUTPUT "" CACHE STRING "Output from TRY_RUN" FORCE)
  SET(HAVE_POLL_FINE_EXITCODE "0" CACHE STRING "Result from TRY_RUN" FORCE)
  SET(HAVE_POLL_FINE ON CACHE STRING "Result from TRY_RUN" FORCE)
endif(CMAKE_CROSSCOMPILING OR APPLE)

# iOS can't to try_compile, so put the results of the tests for iOS here explicitly.
if (APPLE)
  # This is for both iOS and OSX

  # Say what iOS and OSX has explicitly.
  set(HAVE_FCNTL_O_NONBLOCK ON)
  set(HAVE_IOCTLSOCKET OFF)
  set(HAVE_IOCTLSOCKET_CAMEL OFF)
  set(HAVE_IOCTLSOCKET_CAMEL_FIONBIO OFF)
  set(HAVE_IOCTLSOCKET_FIONBIO OFF)
  set(HAVE_IOCTL_FIONBIO ON)
  set(HAVE_IOCTL_SIOCGIFADDR ON)
  set(HAVE_SETSOCKOPT_SO_NONBLOCK ON)
  set(HAVE_SOCKADDR_IN6_SIN6_SCOPE_ID ON)
  set(TIME_WITH_SYS_TIME ON)
  set(HAVE_O_NONBLOCK ON)
  set(HAVE_GETHOSTBYADDR_R_5 ON)
  set(HAVE_GETHOSTBYADDR_R_7 ON)
  set(HAVE_GETHOSTBYADDR_R_8 ON)
  set(HAVE_GETHOSTBYADDR_R_5_REENTRANT ON)
  set(HAVE_GETHOSTBYADDR_R_7_REENTRANT ON)
  set(HAVE_GETHOSTBYADDR_R_8_REENTRANT ON)
  set(HAVE_GETHOSTBYNAME_R_3 ON)
  set(HAVE_GETHOSTBYNAME_R_5 ON)
  set(HAVE_GETHOSTBYNAME_R_6 ON)
  set(HAVE_GETHOSTBYNAME_R_3_REENTRANT ON)
  set(HAVE_GETHOSTBYNAME_R_5_REENTRANT ON)
  set(HAVE_GETHOSTBYNAME_R_6_REENTRANT ON)
  set(HAVE_SOCKLEN_T ON)
  set(HAVE_IN_ADDR_T ON)
  set(HAVE_BOOL_T ON)
  set(STDC_HEADERS ON)
  set(RETSIGTYPE_TEST ON)
  set(HAVE_INET_NTOA_R_DECL OFF)
  set(HAVE_INET_NTOA_R_DECL_REENTRANT OFF)
  set(HAVE_GETADDRINFO ON)
  set(HAVE_FILE_OFFSET_BITS ON)
  if(HAVE_FILE_OFFSET_BITS)
    set(_FILE_OFFSET_BITS 64)
  endif(HAVE_FILE_OFFSET_BITS)

  # Extra iOS and OSX variables that are normally set by tests
  set(RECV_TYPE_ARG1 "int")
  set(RECV_TYPE_ARG2 "void *")
  set(RECV_TYPE_ARG3 "size_t")
  set(RECV_TYPE_ARG4 "int")
  set(RECV_TYPE_RETV "ssize_t")
  set(HAVE_RECV 1)
  set(SEND_QUAL_ARG2 "const")
  set(SEND_TYPE_ARG1 "int")
  set(SEND_TYPE_ARG2 "void *")
  set(SEND_TYPE_ARG3 "size_t")
  set(SEND_TYPE_ARG4 "int")
  set(SEND_TYPE_RETV "ssize_t")
  set(HAVE_SEND 1)
  set(HAVE_STRUCT_TIMEVAL 1)

else(APPLE)
  # Do curl specific tests
  foreach(CURL_TEST
      HAVE_FCNTL_O_NONBLOCK
      HAVE_IOCTLSOCKET
      HAVE_IOCTLSOCKET_CAMEL
      HAVE_IOCTLSOCKET_CAMEL_FIONBIO
      HAVE_IOCTLSOCKET_FIONBIO
      HAVE_IOCTL_FIONBIO
      HAVE_IOCTL_SIOCGIFADDR
      HAVE_SETSOCKOPT_SO_NONBLOCK
      HAVE_SOCKADDR_IN6_SIN6_SCOPE_ID
      TIME_WITH_SYS_TIME
      HAVE_O_NONBLOCK
      HAVE_GETHOSTBYADDR_R_5
      HAVE_GETHOSTBYADDR_R_7
      HAVE_GETHOSTBYADDR_R_8
      HAVE_GETHOSTBYADDR_R_5_REENTRANT
      HAVE_GETHOSTBYADDR_R_7_REENTRANT
      HAVE_GETHOSTBYADDR_R_8_REENTRANT
      HAVE_GETHOSTBYNAME_R_3
      HAVE_GETHOSTBYNAME_R_5
      HAVE_GETHOSTBYNAME_R_6
      HAVE_GETHOSTBYNAME_R_3_REENTRANT
      HAVE_GETHOSTBYNAME_R_5_REENTRANT
      HAVE_GETHOSTBYNAME_R_6_REENTRANT
      HAVE_SOCKLEN_T
      HAVE_IN_ADDR_T
      HAVE_BOOL_T
      STDC_HEADERS
      RETSIGTYPE_TEST
      HAVE_INET_NTOA_R_DECL
      HAVE_INET_NTOA_R_DECL_REENTRANT
      HAVE_GETADDRINFO
      HAVE_FILE_OFFSET_BITS
      )
    curl_internal_test(${CURL_TEST})
  endforeach(CURL_TEST)
  if(HAVE_FILE_OFFSET_BITS)
    set(_FILE_OFFSET_BITS 64)
  endif(HAVE_FILE_OFFSET_BITS)
  foreach(CURL_TEST
      HAVE_GLIBC_STRERROR_R
      HAVE_POSIX_STRERROR_R
      )
    curl_internal_test_run(${CURL_TEST})
  endforeach(CURL_TEST)

  # Check for reentrant
  foreach(CURL_TEST
      HAVE_GETHOSTBYADDR_R_5
      HAVE_GETHOSTBYADDR_R_7
      HAVE_GETHOSTBYADDR_R_8
      HAVE_GETHOSTBYNAME_R_3
      HAVE_GETHOSTBYNAME_R_5
      HAVE_GETHOSTBYNAME_R_6
      HAVE_INET_NTOA_R_DECL_REENTRANT)
    if(NOT ${CURL_TEST})
      if(${CURL_TEST}_REENTRANT)
        set(NEED_REENTRANT 1)
      endif(${CURL_TEST}_REENTRANT)
    endif(NOT ${CURL_TEST})
  endforeach(CURL_TEST)
endif(APPLE)

if(NEED_REENTRANT)
  foreach(CURL_TEST
      HAVE_GETHOSTBYADDR_R_5
      HAVE_GETHOSTBYADDR_R_7
      HAVE_GETHOSTBYADDR_R_8
      HAVE_GETHOSTBYNAME_R_3
      HAVE_GETHOSTBYNAME_R_5
      HAVE_GETHOSTBYNAME_R_6)
    set(${CURL_TEST} 0)
    if(${CURL_TEST}_REENTRANT)
      set(${CURL_TEST} 1)
    endif(${CURL_TEST}_REENTRANT)
  endforeach(CURL_TEST)
endif(NEED_REENTRANT)

if(HAVE_INET_NTOA_R_DECL_REENTRANT)
  set(HAVE_INET_NTOA_R_DECL 1)
  set(NEED_REENTRANT 1)
endif(HAVE_INET_NTOA_R_DECL_REENTRANT)

# Some other minor tests

if(NOT HAVE_IN_ADDR_T)
  set(in_addr_t "unsigned long")
endif(NOT HAVE_IN_ADDR_T)

# Fix libz / zlib.h

if(NOT CURL_SPECIAL_LIBZ)
  if(NOT HAVE_LIBZ)
    set(HAVE_ZLIB_H 0)
  endif(NOT HAVE_LIBZ)

  if(NOT HAVE_ZLIB_H)
    set(HAVE_LIBZ 0)
  endif(NOT HAVE_ZLIB_H)
endif(NOT CURL_SPECIAL_LIBZ)

if(_FILE_OFFSET_BITS)
  set(_FILE_OFFSET_BITS 64)
endif(_FILE_OFFSET_BITS)
set(CMAKE_REQUIRED_FLAGS "-D_FILE_OFFSET_BITS=64")
set(CMAKE_EXTRA_INCLUDE_FILES "${CMAKE_CURRENT_SOURCE_DIR}/curl/curl.h")
if (APPLE)
  set(SIZEOF_CURL_OFF_T ${SIZEOF_SIZE_T})
else(APPLE)
  check_type_size("curl_off_t" SIZEOF_CURL_OFF_T)
endif(APPLE)
set(CMAKE_EXTRA_INCLUDE_FILES)
set(CMAKE_REQUIRED_FLAGS)


# Check for nonblocking
set(HAVE_DISABLED_NONBLOCKING 1)
if(HAVE_FIONBIO OR
    HAVE_IOCTLSOCKET OR
    HAVE_IOCTLSOCKET_CASE OR
    HAVE_O_NONBLOCK)
  set(HAVE_DISABLED_NONBLOCKING)
endif(HAVE_FIONBIO OR
  HAVE_IOCTLSOCKET OR
  HAVE_IOCTLSOCKET_CASE OR
  HAVE_O_NONBLOCK)

if(RETSIGTYPE_TEST)
  set(RETSIGTYPE void)
else(RETSIGTYPE_TEST)
  set(RETSIGTYPE int)
endif(RETSIGTYPE_TEST)

if(CMAKE_COMPILER_IS_GNUCC AND APPLE)
  include(CheckCCompilerFlag)
  check_c_compiler_flag(-Wno-long-double HAVE_C_FLAG_Wno_long_double)
  if(HAVE_C_FLAG_Wno_long_double)
    # The Mac version of GCC warns about use of long double.  Disable it.
    get_source_file_property(MPRINTF_COMPILE_FLAGS mprintf.c COMPILE_FLAGS)
    if(MPRINTF_COMPILE_FLAGS)
      set(MPRINTF_COMPILE_FLAGS "${MPRINTF_COMPILE_FLAGS} -Wno-long-double")
    else(MPRINTF_COMPILE_FLAGS)
      set(MPRINTF_COMPILE_FLAGS "-Wno-long-double")
    endif(MPRINTF_COMPILE_FLAGS)
    set_source_files_properties(mprintf.c PROPERTIES
      COMPILE_FLAGS ${MPRINTF_COMPILE_FLAGS})
  endif(HAVE_C_FLAG_Wno_long_double)
endif(CMAKE_COMPILER_IS_GNUCC AND APPLE)

if(HAVE_SOCKLEN_T)
  set(CURL_TYPEOF_CURL_SOCKLEN_T "socklen_t")
  if(WIN32)
    set(CMAKE_EXTRA_INCLUDE_FILES "winsock2.h;ws2tcpip.h")
  elseif(HAVE_SYS_SOCKET_H)
    set(CMAKE_EXTRA_INCLUDE_FILES "sys/socket.h")
  endif()
  if (APPLE)
    # This is for both iOS and OSX
    set(CURL_SIZEOF_CURL_SOCKLEN_T 4)
    set(HAVE_CURL_SIZEOF_CURL_SOCKLEN_T ON)
  else(APPLE)
    check_type_size("socklen_t" CURL_SIZEOF_CURL_SOCKLEN_T)
  endif(APPLE)
  set(CMAKE_EXTRA_INCLUDE_FILES)
  if(NOT HAVE_CURL_SIZEOF_CURL_SOCKLEN_T)
    message(FATAL_ERROR
     "Check for sizeof socklen_t failed, see CMakeFiles/CMakerror.log")
  endif()
else()
  set(CURL_TYPEOF_CURL_SOCKLEN_T int)
  set(CURL_SIZEOF_CURL_SOCKLEN_T ${SIZEOF_INT})
endif()

# TODO test which of these headers are required for the typedefs used in curlbuild.h
if(WIN32)
  set(CURL_PULL_WS2TCPIP_H ${HAVE_WS2TCPIP_H})
else()
  set(CURL_PULL_SYS_TYPES_H ${HAVE_SYS_TYPES_H})
  set(CURL_PULL_SYS_SOCKET_H ${HAVE_SYS_SOCKET_H})
  set(CURL_PULL_SYS_POLL_H ${HAVE_SYS_POLL_H})
endif()
set(CURL_PULL_STDINT_H ${HAVE_STDINT_H})
set(CURL_PULL_INTTYPES_H ${HAVE_INTTYPES_H})

if(NOT APPLE)
  # This not used for either iOS or OSX
  include(CMake/OtherTests.cmake)
endif(NOT APPLE)

add_definitions(-DHAVE_CONFIG_H)

# For windows, do not allow the compiler to use default target (Vista).
if(WIN32)
  add_definitions(-D_WIN32_WINNT=0x0501)
endif(WIN32)

if(MSVC)
  add_definitions(-D_CRT_SECURE_NO_DEPRECATE -D_CRT_NONSTDC_NO_DEPRECATE)
endif(MSVC)

# Ugly (but functional) way to include "Makefile.inc" by transforming it (= regenerate it).
function(TRANSFORM_MAKEFILE_INC INPUT_FILE OUTPUT_FILE)
  file(READ ${INPUT_FILE} MAKEFILE_INC_TEXT)
  string(REPLACE "$(top_srcdir)"   "\${CURL_SOURCE_DIR}" MAKEFILE_INC_TEXT ${MAKEFILE_INC_TEXT})
  string(REPLACE "$(top_builddir)" "\${CURL_BINARY_DIR}" MAKEFILE_INC_TEXT ${MAKEFILE_INC_TEXT})

  string(REGEX REPLACE "\\\\\n" "ﾧ!ﾧ" MAKEFILE_INC_TEXT ${MAKEFILE_INC_TEXT})
  string(REGEX REPLACE "([a-zA-Z_][a-zA-Z0-9_]*)[\t ]*=[\t ]*([^\n]*)" "SET(\\1 \\2)" MAKEFILE_INC_TEXT ${MAKEFILE_INC_TEXT})
  string(REPLACE "ﾧ!ﾧ" "\n" MAKEFILE_INC_TEXT ${MAKEFILE_INC_TEXT})

  string(REGEX REPLACE "\\$\\(([a-zA-Z_][a-zA-Z0-9_]*)\\)" "\${\\1}" MAKEFILE_INC_TEXT ${MAKEFILE_INC_TEXT})    # Replace $() with ${}
  string(REGEX REPLACE "@([a-zA-Z_][a-zA-Z0-9_]*)@" "\${\\1}" MAKEFILE_INC_TEXT ${MAKEFILE_INC_TEXT})    # Replace @@ with ${}, even if that may not be read by CMake scripts.
  file(WRITE ${OUTPUT_FILE} ${MAKEFILE_INC_TEXT})

endfunction()

add_subdirectory(lib)
if(BUILD_CURL_EXE)
  add_subdirectory(src)
endif()
if(BUILD_CURL_TESTS)
  add_subdirectory(tests)
endif()

# TODO support GNUTLS, NSS, POLARSSL, AXTLS, CYASSL, WINSSL, DARWINSSL
if(USE_OPENSSL)
  set(SSL_ENABLED 1)
endif()

# Helper to populate a list (_items) with a label when conditions (the remaining
# args) are satisfied
function(_add_if label)
  # TODO need to disable policy CMP0054 (CMake 3.1) to allow this indirection
  if(${ARGN})
    set(_items ${_items} "${label}" PARENT_SCOPE)
  endif()
endfunction()

# Clear list and try to detect available features
set(_items)
_add_if("SSL"           SSL_ENABLED)
_add_if("IPv6"          ENABLE_IPV6)
_add_if("unix-sockets"  USE_UNIX_SOCKETS)
_add_if("libz"          HAVE_LIBZ)
_add_if("AsynchDNS"     USE_ARES OR USE_THREADS_POSIX)
_add_if("IDN"           HAVE_LIBIDN)
# TODO SSP1 (WinSSL) check is missing
_add_if("SSPI"          USE_WINDOWS_SSPI)
_add_if("GSS-API"       HAVE_GSS_API)
# TODO SSP1 missing for SPNEGO
_add_if("SPNEGO"        NOT CURL_DISABLE_CRYPTO_AUTH AND
                        (HAVE_GSS_API OR USE_WINDOWS_SSPI))
_add_if("Kerberos"      NOT CURL_DISABLE_CRYPTO_AUTH AND
                        (HAVE_GSS_API OR USE_WINDOWS_SSPI))
# NTLM support requires crypto function adaptions from various SSL libs
# TODO alternative SSL libs tests for SSP1, GNUTLS, NSS, DARWINSSL
if(NOT CURL_DISABLE_CRYPTO_AUTH AND (USE_OPENSSL OR
   USE_WINDOWS_SSPI OR GNUTLS_ENABLED OR NSS_ENABLED OR DARWINSSL_ENABLED))
  _add_if("NTLM"        1)
  # TODO missing option (autoconf: --enable-ntlm-wb)
  _add_if("NTLM_WB"     NOT CURL_DISABLE_HTTP AND NTLM_WB_ENABLED)
endif()
# TODO missing option (--enable-tls-srp), depends on GNUTLS_SRP/OPENSSL_SRP
_add_if("TLS-SRP"       USE_TLS_SRP)
# TODO option --with-nghttp2 tests for nghttp2 lib and nghttp2/nghttp2.h header
_add_if("HTTP2"         USE_NGHTTP2)
string(REPLACE ";" " " SUPPORT_FEATURES "${_items}")
message(STATUS "Enabled features: ${SUPPORT_FEATURES}")

# Clear list and try to detect available protocols
set(_items)
_add_if("HTTP"          NOT CURL_DISABLE_HTTP)
_add_if("HTTPS"         NOT CURL_DISABLE_HTTP AND SSL_ENABLED)
_add_if("FTP"           NOT CURL_DISABLE_FTP)
_add_if("FTPS"          NOT CURL_DISABLE_FTP AND SSL_ENABLED)
_add_if("FILE"          NOT CURL_DISABLE_FILE)
_add_if("TELNET"        NOT CURL_DISABLE_TELNET)
_add_if("LDAP"          NOT CURL_DISABLE_LDAP)
# CURL_DISABLE_LDAP implies CURL_DISABLE_LDAPS
# TODO check HAVE_LDAP_SSL (in autoconf this is enabled with --enable-ldaps)
_add_if("LDAPS"         NOT CURL_DISABLE_LDAPS AND
                        ((USE_OPENLDAP AND SSL_ENABLED) OR
                        (NOT USE_OPENLDAP AND HAVE_LDAP_SSL)))
_add_if("DICT"          NOT CURL_DISABLE_DICT)
_add_if("TFTP"          NOT CURL_DISABLE_TFTP)
_add_if("GOPHER"        NOT CURL_DISABLE_GOPHER)
_add_if("POP3"          NOT CURL_DISABLE_POP3)
_add_if("POP3S"         NOT CURL_DISABLE_POP3 AND SSL_ENABLED)
_add_if("IMAP"          NOT CURL_DISABLE_IMAP)
_add_if("IMAPS"         NOT CURL_DISABLE_IMAP AND SSL_ENABLED)
_add_if("SMTP"          NOT CURL_DISABLE_SMTP)
_add_if("SMTPS"         NOT CURL_DISABLE_SMTP AND SSL_ENABLED)
_add_if("SCP"           USE_LIBSSH2)
_add_if("SFTP"          USE_LIBSSH2)
_add_if("RTSP"          NOT CURL_DISABLE_RTSP)
_add_if("RTMP"          USE_LIBRTMP)
list(SORT _items)
string(REPLACE ";" " " SUPPORT_PROTOCOLS "${_items}")
message(STATUS "Enabled protocols: ${SUPPORT_PROTOCOLS}")

# curl-config needs the following options to be set.
set(CC                      "${CMAKE_C_COMPILER}")
# TODO probably put a -D... options here?
set(CONFIGURE_OPTIONS       "")
# TODO when to set "-DCURL_STATICLIB" for CPPFLAG_CURL_STATICLIB?
set(CPPFLAG_CURL_STATICLIB  "")
# TODO need to set this (see CURL_CHECK_CA_BUNDLE in acinclude.m4)
set(CURL_CA_BUNDLE          "")
set(CURLVERSION             "${CURL_VERSION}")
set(ENABLE_SHARED           "yes")
if(CURL_STATICLIB)
  # Broken: LIBCURL_LIBS below; .a lib is not built
  #message(WARNING "Static linking is broken!")
  set_property(
    TARGET libcurl
    APPEND PROPERTY INTERFACE_COMPILE_DEFINITIONS CURL_STATICLIB=1
  )
  set(ENABLE_STATIC         "yes")
else()
  set(ENABLE_STATIC         "no")
endif()
set(exec_prefix             "\${prefix}")
set(includedir              "\${prefix}/include")
set(LDFLAGS                 "${CMAKE_SHARED_LINKER_FLAGS}")
set(LIBCURL_LIBS            "")
set(libdir                  "${CMAKE_INSTALL_PREFIX}/lib")
# TODO CURL_LIBS also contains absolute paths which don't work with static -l...
foreach(_lib ${CMAKE_C_IMPLICIT_LINK_LIBRARIES} ${CURL_LIBS})
  set(LIBCURL_LIBS          "${LIBCURL_LIBS} -l${_lib}")
endforeach()
# "a" (Linux) or "lib" (Windows)
string(REPLACE "." "" libext "${CMAKE_STATIC_LIBRARY_SUFFIX}")
set(prefix                  "${CMAKE_INSTALL_PREFIX}")
# Set this to "yes" to append all libraries on which -lcurl is dependent
set(REQUIRE_LIB_DEPS        "no")
# SUPPORT_FEATURES
# SUPPORT_PROTOCOLS
set(VERSIONNUM              "${CURL_VERSION_NUM}")

# Finally generate a "curl-config" matching this config
#configure_file("${CURL_SOURCE_DIR}/curl-config.in"
#               "${CURL_BINARY_DIR}/curl-config" @ONLY)
#install(FILES "${CMAKE_BINARY_DIR}/curl-config"
#        DESTINATION bin
#        PERMISSIONS
#          OWNER_READ OWNER_WRITE OWNER_EXECUTE
#          GROUP_READ GROUP_EXECUTE
#          WORLD_READ WORLD_EXECUTE)

# Finally generate a pkg-config file matching this config
#configure_file("${CURL_SOURCE_DIR}/libcurl.pc.in"
#               "${CURL_BINARY_DIR}/libcurl.pc" @ONLY)
#install(FILES "${CMAKE_BINARY_DIR}/libcurl.pc"
#        DESTINATION lib/pkgconfig)

# This needs to be run very last so other parts of the scripts can take advantage of this.
if(NOT CURL_CONFIG_HAS_BEEN_RUN_BEFORE)
  set(CURL_CONFIG_HAS_BEEN_RUN_BEFORE 1 CACHE INTERNAL "Flag to track whether this is the first time running CMake or if CMake has been configured before")
endif()

# Installation.
# First, install generated curlbuild.h
#install(FILES "${CMAKE_CURRENT_BINARY_DIR}/include/curl/curlbuild.h"
#    DESTINATION include/curl )
# Next, install other headers excluding curlbuild.h
#install(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/include/curl"
#    DESTINATION include
#    FILES_MATCHING PATTERN "*.h"
#    PATTERN "curlbuild.h" EXCLUDE)


# Workaround for MSVS10 to avoid the Dialog Hell
# FIXME: This could be removed with future version of CMake.
if(MSVC_VERSION EQUAL 1600)
  set(CURL_SLN_FILENAME "${CMAKE_CURRENT_BINARY_DIR}/CURL.sln")
  if(EXISTS "${CURL_SLN_FILENAME}")
    file(APPEND "${CURL_SLN_FILENAME}" "\n# This should be regenerated!\n")
  endif()
endif()
