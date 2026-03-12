#include "transpiler.hpp"

#include "dictionary.hpp"

#include <cctype>
#include <string>

namespace kpp {
namespace {

bool is_identifier_start(char c) {
  const unsigned char uc = static_cast<unsigned char>(c);
  return std::isalpha(uc) || c == '_' || uc >= 0x80;
}

bool is_identifier_char(char c) {
  const unsigned char uc = static_cast<unsigned char>(c);
  return std::isalnum(uc) || c == '_' || uc >= 0x80;
}

}  // namespace

std::string transpile_to_cpp(const std::string& source) {
  const auto& map = keyword_map();
  std::string out;
  out.reserve(source.size() + source.size() / 10);

  enum class State {
    kNormal,
    kString,
    kChar,
    kLineComment,
    kBlockComment,
  };

  State state = State::kNormal;

  for (std::size_t i = 0; i < source.size();) {
    const char c = source[i];

    if (state == State::kNormal) {
      if (c == '"') {
        state = State::kString;
        out.push_back(c);
        ++i;
        continue;
      }
      if (c == '\'') {
        state = State::kChar;
        out.push_back(c);
        ++i;
        continue;
      }
      if (c == '/' && i + 1 < source.size() && source[i + 1] == '/') {
        state = State::kLineComment;
        out.push_back('/');
        out.push_back('/');
        i += 2;
        continue;
      }
      if (c == '/' && i + 1 < source.size() && source[i + 1] == '*') {
        state = State::kBlockComment;
        out.push_back('/');
        out.push_back('*');
        i += 2;
        continue;
      }

      if (is_identifier_start(c)) {
        std::size_t j = i + 1;
        while (j < source.size() && is_identifier_char(source[j])) {
          ++j;
        }
        const std::string token = source.substr(i, j - i);
        const auto it = map.find(token);
        if (it != map.end()) {
          out += it->second;
        } else {
          out += token;
        }
        i = j;
        continue;
      }

      out.push_back(c);
      ++i;
      continue;
    }

    if (state == State::kString) {
      out.push_back(c);
      ++i;
      if (c == '\\' && i < source.size()) {
        out.push_back(source[i]);
        ++i;
        continue;
      }
      if (c == '"') {
        state = State::kNormal;
      }
      continue;
    }

    if (state == State::kChar) {
      out.push_back(c);
      ++i;
      if (c == '\\' && i < source.size()) {
        out.push_back(source[i]);
        ++i;
        continue;
      }
      if (c == '\'') {
        state = State::kNormal;
      }
      continue;
    }

    if (state == State::kLineComment) {
      out.push_back(c);
      ++i;
      if (c == '\n') {
        state = State::kNormal;
      }
      continue;
    }

    out.push_back(c);
    ++i;
    if (c == '*' && i < source.size() && source[i] == '/') {
      out.push_back('/');
      ++i;
      state = State::kNormal;
    }
  }

  return out;
}

}  // namespace kpp
