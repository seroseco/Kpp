#include "transpiler.hpp"

#include <filesystem>
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>

namespace {

void print_usage() {
  std::cerr << "Usage: kppc <input.kpp> [-o output.cpp] [--stdout]\n";
  std::cerr << "Default output: generated/cpp/<input_stem>.cpp\n";
}

std::string read_file(const std::filesystem::path& path) {
  std::ifstream input(path, std::ios::binary);
  if (!input) {
    throw std::runtime_error("Failed to open input file: " + path.string());
  }
  std::ostringstream buffer;
  buffer << input.rdbuf();
  return buffer.str();
}

void write_file(const std::filesystem::path& path, const std::string& content) {
  if (path.has_parent_path()) {
    std::filesystem::create_directories(path.parent_path());
  }
  std::ofstream output(path, std::ios::binary);
  if (!output) {
    throw std::runtime_error("Failed to open output file: " + path.string());
  }
  output << content;
}

std::filesystem::path default_output_path(const std::filesystem::path& input_path) {
  std::filesystem::path out = std::filesystem::path("generated") / "cpp" / input_path.filename();
  out.replace_extension(".cpp");
  return out;
}

}  // namespace

int main(int argc, char** argv) {
  try {
    if (argc < 2) {
      print_usage();
      return 1;
    }

    std::filesystem::path input_path;
    std::filesystem::path output_path;
    bool to_stdout = false;

    for (int i = 1; i < argc; ++i) {
      const std::string arg = argv[i];
      if (arg == "-o") {
        if (i + 1 >= argc) {
          throw std::runtime_error("Missing value for -o");
        }
        output_path = argv[++i];
      } else if (arg == "--stdout") {
        to_stdout = true;
      } else if (!arg.empty() && arg[0] == '-') {
        throw std::runtime_error("Unknown option: " + arg);
      } else if (input_path.empty()) {
        input_path = arg;
      } else {
        throw std::runtime_error("Unexpected argument: " + arg);
      }
    }

    if (input_path.empty()) {
      throw std::runtime_error("Input file is required.");
    }

    const std::string source = read_file(input_path);
    const std::string output = kpp::transpile_to_cpp(source);

    if (to_stdout) {
      std::cout << output;
      return 0;
    }

    if (output_path.empty()) {
      output_path = default_output_path(input_path);
    }

    write_file(output_path, output);
    std::cout << "Generated: " << output_path.string() << "\n";
    return 0;
  } catch (const std::exception& ex) {
    std::cerr << "Error: " << ex.what() << "\n";
    return 1;
  }
}
