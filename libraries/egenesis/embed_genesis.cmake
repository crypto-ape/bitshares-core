set( CMAKE_CURRENT_SOURCE_DIR ${INIT_SOURCE_DIR} )
set( CMAKE_CURRENT_BINARY_DIR ${INIT_BINARY_DIR} )

file( SHA256 "${embed_genesis_args}" chain_id )
message( STATUS "Generating egenesis" )

message( STATUS "Chain-id: ${chain_id}" )

set( generated_file_banner "/*** GENERATED FILE - DO NOT EDIT! ***/" )
set( genesis_json_hash "${chain_id}" )
configure_file( "${CMAKE_CURRENT_SOURCE_DIR}/egenesis_brief.cpp.tmpl" "${CMAKE_CURRENT_BINARY_DIR}/egenesis_brief.cpp" )

file( READ "${embed_genesis_args}" genesis_json )
string( LENGTH "${genesis_json}" genesis_json_length )
string( REGEX REPLACE "(\"|\\\\)" "\\\\\\1" genesis_json_escaped "${genesis_json}" )
string( REPLACE "\n" "\\n" genesis_json_escaped "${genesis_json_escaped}" )
string( REPLACE "\t" "\\t" genesis_json_escaped "${genesis_json_escaped}" )

if( MSVC )
  # MSVC 2015 is not able to parse string literals that are longer than 16K; nor strings longer thatn 65K

  # CMake does not support {n} REGEX syntax, so generate a sequence of matchable characters
  # parametrizable, should be less than 16k for MSVC 2015
  # because of CMake limitations, max is 8 ( CMake 3.2 )
  set( EMBED_GENESIS_LITERAL_LENGTH 8 )

  set( CPP_CHARACTER_REGEX "\\\\U\\d\\d\\d\\d\\d\\d\\d\\d|\\\\u\\d\\d\\d\\d|\\\\x[0-9a-fA-F][0-9a-fA-F]|\\\\\\d\\d\\d|\\\\." )

  set( REGEX_PATTERN "" )

  # Generate regex pattern that matches a C++ character n-times
  foreach( i RANGE 1 ${EMBED_GENESIS_LITERAL_LENGTH} )
    set( REGEX_PATTERN "${REGEX_PATTERN}(${CPP_CHARACTER_REGEX}|.)" )
  endforeach( i RANGE 1 ${EMBED_GENESIS_LITERAL_LENGTH} )

  string( REGEX REPLACE "(${REGEX_PATTERN})" "\\1\",\n \"" genesis_json_escaped ${genesis_json_escaped} )

  set( genesis_json_escaped "\"${genesis_json_escaped}\"" )

  # Delete trailing empty literal
  string( REGEX REPLACE ",\n \"\"" "" genesis_json_escaped ${genesis_json_escaped} )

  math( EXPR genesis_json_array_height "(${genesis_json_length} + ${EMBED_GENESIS_LITERAL_LENGTH} - 1)/${EMBED_GENESIS_LITERAL_LENGTH}" )
  set( genesis_json_array_width "${EMBED_GENESIS_LITERAL_LENGTH}" )
else( MSVC )
  set( genesis_json_array_height 1 )
  set( genesis_json_array_width ${genesis_json_length} )

  set( genesis_json_escaped "\"${genesis_json_escaped}\"" )
endif( MSVC )
set( genesis_json_array "${genesis_json_escaped}" )


configure_file( "${CMAKE_CURRENT_SOURCE_DIR}/egenesis_full.cpp.tmpl" "${CMAKE_CURRENT_BINARY_DIR}/egenesis_full.cpp" )
