#-----------------------------------------------------------------------------
set(MODULE_NAME ${EXTENSION_NAME}) # Do not use 'project()'
set(MODULE_TITLE ${MODULE_NAME})

string(TOUPPER ${MODULE_NAME} MODULE_NAME_UPPER)


## A simple macro to set variables ONLY if it has not been set
## This is needed when stand-alone packages are combined into
## a larger package, and the desired behavior is that all the
## binary results end up in the combined directory.
if(NOT SETIFEMPTY)
macro(SETIFEMPTY)
  set(KEY ${ARGV0})
  set(VALUE ${ARGV1})
  if(NOT ${KEY})
    set(${KEY} ${VALUE})
  endif(NOT ${KEY})
endmacro(SETIFEMPTY KEY VALUE)
endif(NOT SETIFEMPTY)
###
SETIFEMPTY(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/lib)
SETIFEMPTY(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/lib)
SETIFEMPTY(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/bin)
SETIFEMPTY(INSTALL_RUNTIME_DESTINATION bin)
SETIFEMPTY(INSTALL_LIBRARY_DESTINATION lib)
SETIFEMPTY(INSTALL_ARCHIVE_DESTINATION lib/static)
SETIFEMPTY(CLI_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_RUNTIME_OUTPUT_DIRECTORY} )
SETIFEMPTY(CLI_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_LIBRARY_OUTPUT_DIRECTORY} )
SETIFEMPTY(CLI_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_ARCHIVE_OUTPUT_DIRECTORY} )
SETIFEMPTY(CLI_INSTALL_RUNTIME_DESTINATION ${INSTALL_RUNTIME_DESTINATION} )
SETIFEMPTY(CLI_INSTALL_LIBRARY_DESTINATION ${INSTALL_LIBRARY_DESTINATION} )
SETIFEMPTY(CLI_INSTALL_ARCHIVE_DESTINATION ${INSTALL_ARCHIVE_DESTINATION} )

option(BUILD_dwiAtlas "Build dwiAtlas or not.  Requires boost." OFF)
option(BUILD_TESTING "Build the testing tree" ON)

##  In many cases sub-projects depending on SlicerExectuion Model
##  that can be built stand alone are combined in larger packages.
##  This logic will include SlicerExectionModel only if it
##  has not already been included by a previous package.

find_package(SlicerExecutionModel REQUIRED)
include(${SlicerExecutionModel_USE_FILE})

if(NOT ITK_FOUND)
    find_package(ITK REQUIRED)
    include(${ITK_USE_FILE})
else()
  if( NOT DEFINED ITKV3_COMPATIBILITY OR NOT ${ITKV3_COMPATIBILITY}  )
    message( WARNING "Choose ITKv4 compiled with ITKV3_COMPATIBILITY set to ON (or GenerateCLP compiled against such an ITK version). If not, you may have compilation errors" )
  endif()
endif(NOT ITK_FOUND)


if(NOT VTK_FOUND)
    find_package(VTK REQUIRED)
    include(${VTK_USE_FILE})
endif(NOT VTK_FOUND)

##  In many cases stand-alone sub-projects include private versions
##  of DicomToNrrd
##  that can be built stand alone are combined in larger packages.
##  This logic will include DicomToNrrd only if it
##  has not already been included by a previous package.
if(NOT ADDFIRSTINSTANCE_DIRECTORY)
macro(ADDFIRSTINSTANCE_DIRECTORY PROJECT_NAMESPACE STANDALONENAME)
  if(BUILD${STANDALONENAME}FROM${PROJECT_NAMESPACE} OR NOT ${STANDALONENAME}_ALREADYINCLUDED)
    set(BUILD${STANDALONENAME}FROM${PROJECT_NAMESPACE} ON CACHE BOOL "FLAG FOR ${STANDALONENAME} building to prevent recursion.")
    set(${STANDALONENAME}_ALREADYINCLUDED ON CACHE BOOL "FLAG FOR ${STANDALONENAME} to indicate that it is already included.")
    add_subdirectory(${STANDALONENAME})
  endif( BUILD${STANDALONENAME}FROM${PROJECT_NAMESPACE} OR NOT ${STANDALONENAME}_ALREADYINCLUDED)
endmacro(ADDFIRSTINSTANCE_DIRECTORY)
endif(NOT ADDFIRSTINSTANCE_DIRECTORY)
###

INCLUDE_DIRECTORIES(
${DTIProcess_SOURCE_DIR}/Library
${DTIProcess_SOURCE_DIR}/PrivateLibrary
${DTIProcess_SOURCE_DIR}
)

## Replace bessel(FORTRAN) with cephes(C)
SET(BESSEL_LIB cephes)
ADD_SUBDIRECTORY(cephes)

ADD_SUBDIRECTORY(Library)
ADD_SUBDIRECTORY(PrivateLibrary)
ADD_SUBDIRECTORY(Applications)

if( EXTENSION_SUPERBUILD_BINARY_DIR )
  unsetForSlicer( VERBOSE NAMES SlicerExecutionModel_DIR ITK_DIR VTK_DIR CMAKE_C_COMPILER CMAKE_CXX_COMPILER CMAKE_CXX_FLAGS CMAKE_C_FLAGS ITK_LIBRARIES )
  find_package(Slicer REQUIRED)
  include(${Slicer_USE_FILE})
resetForSlicer( VERBOSE NAMES ITK_DIR SlicerExecutionModel_DIR CMAKE_C_COMPILER CMAKE_CXX_COMPILER CMAKE_CXX_FLAGS CMAKE_C_FLAGS ITK_LIBRARIES )
endif()

IF(BUILD_TESTING)
  ADD_SUBDIRECTORY(Testing)
ENDIF(BUILD_TESTING)


if( EXTENSION_SUPERBUILD_BINARY_DIR )
  if(APPLE)
    install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/InstallApple/lib DESTINATION ${CLI_INSTALL_RUNTIME_DESTINATION}/..)
    install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/InstallApple/Frameworks DESTINATION ${CLI_INSTALL_RUNTIME_DESTINATION}/..)
    install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/InstallApple/AppleCreateLinkLibs.sh DESTINATION ${CLI_INSTALL_RUNTIME_DESTINATION}/../share)
  endif(APPLE)
  set(CPACK_INSTALL_CMAKE_PROJECTS "${CPACK_INSTALL_CMAKE_PROJECTS};${CMAKE_BINARY_DIR};${EXTENSION_NAME};ALL;/")
  include(${Slicer_EXTENSION_CPACK})
else()
  if( NOT WIN32 )
    set( Tools  dtiaverage dtiestim dtiprocess fiberprocess fiberstats fibertrack maxcurvature scalartransform )
    foreach( tool ${Tools} )
      install(PROGRAMS ${CLI_RUNTIME_OUTPUT_DIRECTORY}/${tool} DESTINATION ${CLI_INSTALL_RUNTIME_DESTINATION})
    endforeach()
  else()
    message( WARNING "No install on Windows" )
  endif()
endif()
