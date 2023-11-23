# IDP Actions

Contains the github actions to build internal developer platform.

# port-packages:

This github action will allow to report the packages used in the repository to
port.

## Usage:
You can use this action wherever you need in your job to report packages used.
This requires `PORT_CLIENT_ID` and `PORT_CLIENT_SECRET` in order to report. And
outputs packages which is a list of packages along with version and
package-identifiers which contains list of unique package identifier.

