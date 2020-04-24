#include "utilities.cuh"
struct stat info;
int fileExists(const char* const path) {
	return stat(path, &info);
}

int dirExists(const char* const path)
{
	int statRC = stat(path, &info);
	if (statRC != 0)
	{
		if (errno == ENOENT) { return 0; } // something along the path does not exist
		if (errno == ENOTDIR) { return 0; } // something in path prefix is not a dir
		return -1;
	}

	return (info.st_mode & S_IFDIR) ? 1 : 0;
}

void CreateDir(char* path)
{
	char copy_path[80];
	strcpy(copy_path, path);

	if (dirExists(path) == 1)
	{
		return;
	}
	char chars_array[80];
	strcpy(chars_array, strtok(copy_path, "/"));

	while (chars_array)
	{
		CreateDirectory(chars_array, NULL);
		if (dirExists(path) == 1)
		{
			return;
		}
		strcat(chars_array, "/");
		strcat(chars_array, strtok(NULL, "/"));
	}
	return;
}

int count_lines(char path[])
{
	char linebuf[1024];
	FILE* input = fopen(path, "r");
	int lineno = 0;
	while (char* line = fgets(linebuf, 1024, input))
	{
		++lineno;
	}
	fclose(input);
	return lineno;
}

int extractIntegers(char* str) {
	char buffer[33];
	int count = 0;
	//printf("%zd\n", strlen(str));
	for (int i = 0; i < strlen(str); i++) {
		if (isdigit(str[i])) {
			// strcat(buffer,atoi(str[i]));
			buffer[count] = str[i];
			count++;
		}
	}

	return atoi(buffer);
}

char* getMainPath(char* main_path) {
	if (dirExists("results") == 0) {
		strcpy(main_path, "./results/simulation 1");
		return main_path;
	}

	strcpy(main_path, "./results/simulation ");

	const char* PATH = "./results";

	DIR* dir = opendir(PATH);

	struct dirent* entry = readdir(dir);

	char tmp1[1024];
	char tmp2[1024];
	std::vector<int>arr;
	strcpy(tmp1, "simulation");

	while (entry != NULL)
	{
		strcpy(tmp2, entry->d_name);
		// printf("%s\n", entry->d_name);
		if (entry->d_type == DT_DIR && strstr(tmp2, tmp1) != 0) {
			//printf("%s\n", entry->d_name);
			int integer = extractIntegers(tmp2);
			//printf("%d\n", integer);
			arr.push_back(integer);
		}
		entry = readdir(dir);
	}

	closedir(dir);

	if (arr.empty()) {
		strcat(main_path, "1 ");
		return main_path;
	}

	// for (int i = 0; i<12;i++){
	//     printf("%d\n", arr[0]);
	// }

	std::vector<int>::iterator max_value = std::max_element(arr.begin(), arr.end());
	//printf("%d\n", max_value[0] + 1);
	char buffer[1024];
	itoa(max_value[0] + 1, buffer, 10);
	//printf("%s\n", buffer);
	strcat(main_path, buffer);

	return main_path;
}

char* clearAddressArray(char* buffer, char* s1, char* s2)
{
	size_t size1 = strlen(s1);
	size_t size2 = strlen(s2);
	size_t max_len;

	if (size1 > size2)
	{
		max_len = size1;
		buffer = s1;
	}
	else
	{
		max_len = size2;
		buffer = s2;
	}

	int count = 0;

	for (int i = 0; i < max_len; i++) {
		if (s1[i] == s2[i]) {
			count++;
		}
	}

	for (int i = 0; i < count; i++) {
		for (int k = 0; k < max_len; k++) {
			buffer[k] = buffer[k + 1];
		}
	}

	return buffer;
}

void cudaAtributes(void *dev_ptr) {
	cudaPointerAttributes* atributes = new cudaPointerAttributes;
	cudaPointerGetAttributes(atributes, dev_ptr);
	printf("%d %d %d hptr = %p dptr = %p\n", static_cast<int>(atributes->memoryType), atributes->device, atributes->isManaged, atributes->devicePointer, atributes->hostPointer);
	return;
}