#the usual set of dependencies
find_package(OpenGL REQUIRED)
find_package(GLEW REQUIRED)
find_package(SDL REQUIRED)
find_package(SDL_mixer REQUIRED)
find_package(SDL_net REQUIRED)
find_package(SDL_image REQUIRED)
find_package(SDL_ttf REQUIRED)

#compile our rtl implementation
include_directories(${GLEW_INCLUDE_DIR})
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/rtl)
include_directories(${PHYSFS_INCLUDE_DIR})
include_directories(${PHYSLAYER_INCLUDE_DIR})
include_directories(${LUA_INCLUDE_DIR})
include_directories(${SDL_INCLUDE_DIR})
add_subdirectory(rtl)

configure_file(${CMAKE_SOURCE_DIR}/hedgewars/config.inc.in ${CMAKE_CURRENT_BINARY_DIR}/config.inc)

#get the list of pas files that are going to be converted and compiled
file(GLOB engine_sources_pas "${CMAKE_SOURCE_DIR}/hedgewars/*.pas")
#TODO: temporary until cmake can configure itself accordingly
list(REMOVE_ITEM engine_sources_pas "${CMAKE_SOURCE_DIR}/hedgewars/uWeb.pas")
list(REMOVE_ITEM engine_sources_pas "${CMAKE_SOURCE_DIR}/hedgewars/uVideoRec.pas")
list(REMOVE_ITEM engine_sources_pas "${CMAKE_SOURCE_DIR}/hedgewars/uTouch.pas")
list(REMOVE_ITEM engine_sources_pas "${CMAKE_SOURCE_DIR}/hedgewars/PNGh.pas")
list(REMOVE_ITEM engine_sources_pas "${CMAKE_SOURCE_DIR}/hedgewars/pas2cSystem.pas")
list(REMOVE_ITEM engine_sources_pas "${CMAKE_SOURCE_DIR}/hedgewars/pas2cRedo.pas")
list(REMOVE_ITEM engine_sources_pas "${CMAKE_SOURCE_DIR}/hedgewars/hwLibrary.pas")

#remove and readd hwengine so that it is compiled first, compiling every other file in the process
list(REMOVE_ITEM engine_sources_pas ${CMAKE_SOURCE_DIR}/hedgewars/hwengine.pas)
list(APPEND engine_sources_pas ${CMAKE_SOURCE_DIR}/hedgewars/hwengine.pas)

#process files .pas -> .c
foreach(sourcefile ${engine_sources_pas})
    get_filename_component(sourcename ${sourcefile} NAME_WE) #drops .pas
    list(APPEND engine_sources "${CMAKE_CURRENT_BINARY_DIR}/${sourcename}.c")
endforeach()

#add again files for external functions and for fpcrtl_ functions
list(APPEND engine_sources_pas ${CMAKE_SOURCE_DIR}/hedgewars/pas2cSystem.pas)
list(APPEND engine_sources_pas ${CMAKE_SOURCE_DIR}/hedgewars/pas2cRedo.pas)


#invoke pas2c on main module, it will call all the others
add_custom_command(OUTPUT ${engine_sources}
                   COMMAND "${EXECUTABLE_OUTPUT_PATH}/pas2c${CMAKE_EXECUTABLE_SUFFIX}"
                   ARGS -n "hwengine"
                        -i "${CMAKE_SOURCE_DIR}/hedgewars"
                        -o "${CMAKE_CURRENT_BINARY_DIR}"
                        -a "${CMAKE_CURRENT_BINARY_DIR}"
                        -d "ENDIAN_LITTLE"
                        -d "DEBUGFILE"
                   DEPENDS pas2c                     #converter tool
                           ${engine_sources_pas}     #original pascal file
                  )

#wrap conversion for all source in this command
add_custom_target(engine_c DEPENDS ${engine_sources})


#compile the c files
add_definitions(-DPAS2C)
add_definitions(-Werror=incompatible-pointer-types)

add_executable(hwengine WIN32 ${engine_sources})

target_link_libraries(hwengine  fpcrtl
                                ${LUA_LIBRARY}
                                ${OPENGL_LIBRARY}
                                ${SDL_LIBRARY}
                                ${SDLMIXER_LIBRARY}
                                ${SDLNET_LIBRARY}
                                ${SDLIMAGE_LIBRARY}
                                ${SDLTTF_LIBRARY}
                                ${GLEW_LIBRARY}
                                physfs
                                physlayer
                                m
                                #TODO: add other libraries
                            )
if(APPLE)
    target_link_libraries(hwengine IOKit SDLmain)
endif()

install(PROGRAMS "${EXECUTABLE_OUTPUT_PATH}/hwengine${CMAKE_EXECUTABLE_SUFFIX}" DESTINATION ${target_binary_install_dir})

