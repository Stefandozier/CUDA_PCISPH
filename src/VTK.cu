#include "VTK.cuh"
#include "utilities.cuh"
//#include <string.h>

void VTU_Writer(char path[], int iteration, vec3d* points, int numberOfPoints, float** pointData[], vec3d** vectorData[], std::string pointDataNames[], std::string vectorDataNames[], int size_pointData, int size_vectorData, char* fullpath, int type)
{
	if (type == 0) {
		char buffer[50];
		itoa(iteration, buffer, 10);
		strcpy(fullpath, path);
		strcat(fullpath, "/iter");
		strcat(fullpath, buffer);
		strcat(fullpath, ".vtu");
	}
	else if (type == 1) {
		strcpy(fullpath, path);
		strcat(fullpath, "/boundary.vtu");
	} 

	std::ofstream vtu_file;
	vtu_file.open(fullpath);
	
	vtu_file << "<VTKFile type=\"UnstructuredGrid\" version=\"0.1\" byte_order=\"BigEndian\">\n"
		<< "<UnstructuredGrid>\n"
		<< "<Piece NumberOfPoints=\"" << numberOfPoints << "\" NumberOfCells=\"" << numberOfPoints << "\">\n"
		<< "<Points>\n"
		<< "<DataArray type=\"Float32\" NumberOfComponents=\"3\" format=\"ascii\">\n";
	for (int i = 0; i < numberOfPoints; i++) {
		vtu_file << points[i].x << " " << points[i].y << " " << points[i].z << "\n";
	}
	vtu_file << "</DataArray>\n"
		<< "</Points>\n";

	vtu_file << "<PointData Scalars=\"" << pointDataNames[0] << "\">\n";

	for (int i = 0; i < size_pointData; i++) {
		float* data = *pointData[i];
		std::string name = pointDataNames[i];

		vtu_file << "<DataArray type=\"Float32\" Name=\"" << name << "\" NumberOfComponents=\"1\" format=\"ascii\">\n";
		for (int j = 0; j < numberOfPoints; j++) {
			vtu_file << data[j] << "\n";
		}
		vtu_file << "</DataArray>\n";
	}

	for (int i = 0; i < size_vectorData; i++) {
		vec3d* data = *vectorData[i];
		std::string name = vectorDataNames[i];

		vtu_file << "<DataArray type=\"Float32\" Name=\"" << name << "\" NumberOfComponents=\"3\" format=\"ascii\">\n";
		for (int j = 0; j < numberOfPoints; j++) {
			vtu_file << data[j].x << " " << data[j].y << " " << data[j].z << "\n";
		}
		vtu_file << "</DataArray>\n";
	}

	vtu_file << "</PointData>\n"
		<< "<Cells>\n"
		<< "<DataArray type=\"Int32\" Name=\"connectivity\" NumberOfComponents=\"1\" format=\"ascii\">\n";

	for (int i = 0; i < numberOfPoints; i++) {
		vtu_file << i << std::endl;
	}

	vtu_file << "</DataArray>\n"
		<< "<DataArray type=\"Int32\" Name=\"offsets\" NumberOfComponents=\"1\" format=\"ascii\">\n";
	for (int i = 0; i < numberOfPoints; i++) {
		vtu_file << i << " ";
	}

	vtu_file << "\n" << "</DataArray>\n"
		<< "<DataArray type=\"Float32\" Name=\"types\" NumberOfComponents=\"1\" format=\"ascii\">\n";

	for (int i = 0; i < numberOfPoints; i++) {
		vtu_file << 1 << " ";
	}

	vtu_file << "\n" << "</DataArray>\n"
		<< "</Cells>\n";

	vtu_file << "</Piece>\n"
		<< "</UnstructuredGrid>\n"
		<< "</VTKFile>";
	vtu_file.close();
	return;
}

void VTK_Group(char vtk_group_path[], char vtu_path[], float time) {
	//std::cout << vtk_group_path << std::endl;
	char buffer[65];
	strcpy(buffer, clearAddressArray(buffer, vtk_group_path, vtu_path));

	if (fileExists(vtk_group_path) == 0) {
		std::fstream vtk_group;
		vtk_group.open(vtk_group_path);
		vtk_group.seekg(-25, std::ios::end);
		vtk_group << "<DataSet timestep=\"" << time << "\" group=\"\" part=\"0\" file=\"" << buffer << "\"/>\n"
			<< "</Collection>\n"
			<< "</VTKFile>";
		vtk_group.close();
	}
	else {
		std::ofstream vtk_group;
		vtk_group.open(vtk_group_path);
		vtk_group << "<VTKFile type=\"Collection\" version=\"0.1\" byte_order=\"LittleEndian\">\n"
			<< "<Collection>\n"
			<< "<DataSet timestep=\"" << time << "\" group=\"\" part=\"0\" file=\"" << buffer << "\"/>\n"
			<< "</Collection>\n"
			<< "</VTKFile>";
		vtk_group.close();
	}

	return;
}

void readVTU(char* iter_path, vec3d* position, vec3d* velocity) {

	std::ifstream vtu_file(iter_path);

	vtu_file.seekg(222, std::ios::beg);

	char* float_buffer = new char[50];

	int buff_index = 0;
	int vec_index = 0;
	int axis = 0;
	for (char write2line; vtu_file.get(write2line);) {
		if (write2line == 60) { //if the currect char is not equal to <
			break;
		} 
		else if (isdigit(write2line) || write2line == 46 || write2line == 45) {
			float_buffer[buff_index] = write2line;
			buff_index++;
		}
		else if (write2line == 32 || write2line == 10) {
			if (axis == 0) {
				position[vec_index].x = (float)atof(float_buffer);
				axis++;
			}
			else if (axis == 1) {
				position[vec_index].y = (float)atof(float_buffer);
				axis++;
			}
			else {
				position[vec_index].z = (float)atof(float_buffer);
				axis = 0;
				vec_index++;
			}
			float_buffer = new char[50];
			buff_index = 0;
		}

	}

	vtu_file.seekg(0, std::ios::beg);
	char* row = new char[100];
	buff_index = 0;
	unsigned long int char_count = 0;
	bool starts_with_60 = false;
	for (char write2line; vtu_file.get(write2line);) {
		if (write2line == 10 && starts_with_60) {

			if (strstr(row, "velocity") != nullptr) {
				char_count += 2;
				break;
			}

			row = new char[100];
			buff_index = 0;
			starts_with_60 = false;

		}
		else {
			if (starts_with_60) {
				row[buff_index] = write2line;
				buff_index++;
			} else if (write2line == 60) {
				starts_with_60 = true;
				row[buff_index] = write2line;
				buff_index++;
			}

		}
		char_count++;
		if (write2line == 10) {
			char_count++;
		}
	}

	vtu_file.seekg(char_count, std::ios::beg);

	//std::ofstream tmp;
	//tmp.open("tmp.txt");

	buff_index = 0;
	vec_index = 0;
	axis = 0;
	float_buffer = new char[50];
	for (char write2line; vtu_file.get(write2line);) {
		//tmp << write2line;
		if (write2line == 60) { //if the currect char is not equal to <
			break;
		}
		else if (isdigit(write2line) || write2line == 46 || write2line == 45) {
			float_buffer[buff_index] = write2line;
			buff_index++;
		}
		else if (write2line == 32 || write2line == 10) {

			if (axis == 0) {
				velocity[vec_index].x = (float)atof(float_buffer);
				axis++;
			}
			else if (axis == 1) {
				velocity[vec_index].y = (float)atof(float_buffer);
				axis++;
			}
			else {
				velocity[vec_index].z = (float)atof(float_buffer);
				axis = 0;
				vec_index++;
			}
			float_buffer = new char[50];
			buff_index = 0;
		}

	}
	//tmp.close();
	vtu_file.close();
	return;
}