String extractAfterFirstSlash(String input) {
  // Find the index of the first '/'
  int firstSlashIndex = input.indexOf('/');

  // If '/' is not found, return an empty string or handle it as per your requirement
  if (firstSlashIndex == -1) {
    return ''; // or throw an exception or return null
  }

  // Return everything after the first '/'
  // We add 1 to move past the '/' itself
  return input.substring(firstSlashIndex + 1);
}
