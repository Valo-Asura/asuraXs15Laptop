#include "picker/renderer.hpp"

#include "core/color_sort.hpp"

#include <algorithm>
#include <array>
#include <cctype>
#include <cmath>
#include <cstring>
#include <iostream>
#include <stdexcept>
#include <vips/vips8>

namespace vibewall::picker {

namespace {
void init_vips_once() {
  static bool initialized = [] {
    if (VIPS_INIT("vibewallREzero-picker") != 0) {
      throw std::runtime_error("failed to initialize libvips");
    }
    return true;
  }();
  (void)initialized;
}

GLuint compile_shader(GLenum type, const char *source) {
  const GLuint shader = glCreateShader(type);
  glShaderSource(shader, 1, &source, nullptr);
  glCompileShader(shader);
  GLint ok = 0;
  glGetShaderiv(shader, GL_COMPILE_STATUS, &ok);
  if (!ok) {
    char log[2048];
    glGetShaderInfoLog(shader, sizeof(log), nullptr, log);
    throw std::runtime_error("shader compile failed: " + std::string(log));
  }
  return shader;
}

GLuint create_program() {
  static constexpr const char *vertex = R"GLSL(
    attribute vec2 a_pos;
    attribute vec2 a_uv;
    varying vec2 v_uv;
    void main() {
      v_uv = a_uv;
      gl_Position = vec4(a_pos, 0.0, 1.0);
    }
  )GLSL";
  static constexpr const char *fragment = R"GLSL(
    precision mediump float;
    varying vec2 v_uv;
    uniform sampler2D u_texture;
    uniform vec4 u_color;
    uniform int u_use_texture;
    void main() {
      vec4 base = u_use_texture == 1 ? texture2D(u_texture, v_uv) : vec4(1.0);
      gl_FragColor = base * u_color;
    }
  )GLSL";
  const GLuint vs = compile_shader(GL_VERTEX_SHADER, vertex);
  const GLuint fs = compile_shader(GL_FRAGMENT_SHADER, fragment);
  const GLuint program = glCreateProgram();
  glAttachShader(program, vs);
  glAttachShader(program, fs);
  glLinkProgram(program);
  glDeleteShader(vs);
  glDeleteShader(fs);
  GLint ok = 0;
  glGetProgramiv(program, GL_LINK_STATUS, &ok);
  if (!ok) {
    char log[2048];
    glGetProgramInfoLog(program, sizeof(log), nullptr, log);
    throw std::runtime_error("program link failed: " + std::string(log));
  }
  return program;
}

float ndc_x(float x, int width) {
  return (x / static_cast<float>(width)) * 2.0F - 1.0F;
}

float ndc_y(float y, int height) {
  return 1.0F - (y / static_cast<float>(height)) * 2.0F;
}

std::array<float, 4> color_from_group(ColorGroup group) {
  switch (group) {
  case ColorGroup::Red:
    return {0.95F, 0.22F, 0.25F, 1.0F};
  case ColorGroup::Orange:
    return {0.95F, 0.50F, 0.18F, 1.0F};
  case ColorGroup::Yellow:
    return {0.90F, 0.78F, 0.18F, 1.0F};
  case ColorGroup::Lime:
    return {0.55F, 0.85F, 0.20F, 1.0F};
  case ColorGroup::Green:
    return {0.20F, 0.75F, 0.38F, 1.0F};
  case ColorGroup::Cyan:
    return {0.15F, 0.75F, 0.85F, 1.0F};
  case ColorGroup::Blue:
    return {0.25F, 0.45F, 0.95F, 1.0F};
  case ColorGroup::Purple:
    return {0.58F, 0.38F, 0.92F, 1.0F};
  case ColorGroup::Pink:
    return {0.92F, 0.35F, 0.75F, 1.0F};
  case ColorGroup::Brown:
    return {0.56F, 0.36F, 0.20F, 1.0F};
  case ColorGroup::White:
    return {0.92F, 0.92F, 0.86F, 1.0F};
  case ColorGroup::Gray:
    return {0.42F, 0.46F, 0.52F, 1.0F};
  case ColorGroup::Black:
    return {0.12F, 0.13F, 0.16F, 1.0F};
  }
  return {0.2F, 0.2F, 0.2F, 1.0F};
}

bool point_in_polygon(float x, float y, const std::vector<Point> &points) {
  bool inside = false;
  for (std::size_t i = 0, j = points.size() - 1; i < points.size(); j = i++) {
    const bool intersect = ((points[i].y > y) != (points[j].y > y)) &&
                           (x < (points[j].x - points[i].x) * (y - points[i].y) /
                                            (points[j].y - points[i].y + 0.0001F) +
                                        points[i].x);
    if (intersect) {
      inside = !inside;
    }
  }
  return inside;
}

std::array<std::uint8_t, 7> glyph(char c) {
  switch (c) {
  case 'A': return {0x0E,0x11,0x11,0x1F,0x11,0x11,0x11};
  case 'B': return {0x1E,0x11,0x11,0x1E,0x11,0x11,0x1E};
  case 'C': return {0x0F,0x10,0x10,0x10,0x10,0x10,0x0F};
  case 'D': return {0x1E,0x11,0x11,0x11,0x11,0x11,0x1E};
  case 'E': return {0x1F,0x10,0x10,0x1E,0x10,0x10,0x1F};
  case 'F': return {0x1F,0x10,0x10,0x1E,0x10,0x10,0x10};
  case 'G': return {0x0F,0x10,0x10,0x13,0x11,0x11,0x0F};
  case 'H': return {0x11,0x11,0x11,0x1F,0x11,0x11,0x11};
  case 'I': return {0x1F,0x04,0x04,0x04,0x04,0x04,0x1F};
  case 'J': return {0x01,0x01,0x01,0x01,0x11,0x11,0x0E};
  case 'K': return {0x11,0x12,0x14,0x18,0x14,0x12,0x11};
  case 'L': return {0x10,0x10,0x10,0x10,0x10,0x10,0x1F};
  case 'M': return {0x11,0x1B,0x15,0x15,0x11,0x11,0x11};
  case 'N': return {0x11,0x19,0x15,0x13,0x11,0x11,0x11};
  case 'O': return {0x0E,0x11,0x11,0x11,0x11,0x11,0x0E};
  case 'P': return {0x1E,0x11,0x11,0x1E,0x10,0x10,0x10};
  case 'Q': return {0x0E,0x11,0x11,0x11,0x15,0x12,0x0D};
  case 'R': return {0x1E,0x11,0x11,0x1E,0x14,0x12,0x11};
  case 'S': return {0x0F,0x10,0x10,0x0E,0x01,0x01,0x1E};
  case 'T': return {0x1F,0x04,0x04,0x04,0x04,0x04,0x04};
  case 'U': return {0x11,0x11,0x11,0x11,0x11,0x11,0x0E};
  case 'V': return {0x11,0x11,0x11,0x11,0x11,0x0A,0x04};
  case 'W': return {0x11,0x11,0x11,0x15,0x15,0x1B,0x11};
  case 'X': return {0x11,0x11,0x0A,0x04,0x0A,0x11,0x11};
  case 'Y': return {0x11,0x11,0x0A,0x04,0x04,0x04,0x04};
  case 'Z': return {0x1F,0x01,0x02,0x04,0x08,0x10,0x1F};
  case '0': return {0x0E,0x11,0x13,0x15,0x19,0x11,0x0E};
  case '1': return {0x04,0x0C,0x04,0x04,0x04,0x04,0x0E};
  case '2': return {0x0E,0x11,0x01,0x02,0x04,0x08,0x1F};
  case '3': return {0x1E,0x01,0x01,0x0E,0x01,0x01,0x1E};
  case '4': return {0x02,0x06,0x0A,0x12,0x1F,0x02,0x02};
  case '5': return {0x1F,0x10,0x10,0x1E,0x01,0x01,0x1E};
  case '6': return {0x0E,0x10,0x10,0x1E,0x11,0x11,0x0E};
  case '7': return {0x1F,0x01,0x02,0x04,0x08,0x08,0x08};
  case '8': return {0x0E,0x11,0x11,0x0E,0x11,0x11,0x0E};
  case '9': return {0x0E,0x11,0x11,0x0F,0x01,0x01,0x0E};
  case '-': return {0x00,0x00,0x00,0x1F,0x00,0x00,0x00};
  case '_': return {0x00,0x00,0x00,0x00,0x00,0x00,0x1F};
  case '.': return {0x00,0x00,0x00,0x00,0x00,0x0C,0x0C};
  case '/': return {0x01,0x01,0x02,0x04,0x08,0x10,0x10};
  case ':': return {0x00,0x0C,0x0C,0x00,0x0C,0x0C,0x00};
  default: return {0x00,0x00,0x00,0x00,0x00,0x00,0x00};
  }
}
} // namespace

void Renderer::init() {
  init_vips_once();
  program_ = create_program();
  pos_loc_ = glGetAttribLocation(program_, "a_pos");
  uv_loc_ = glGetAttribLocation(program_, "a_uv");
  color_loc_ = glGetUniformLocation(program_, "u_color");
  use_texture_loc_ = glGetUniformLocation(program_, "u_use_texture");
  texture_loc_ = glGetUniformLocation(program_, "u_texture");
  glUseProgram(program_);
  glUniform1i(texture_loc_, 0);
  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
}

void Renderer::resize(int width, int height) {
  width_ = std::max(1, width);
  height_ = std::max(1, height);
  glViewport(0, 0, width_, height_);
}

GLuint Renderer::texture_for(const Wallpaper &wallpaper) {
  if (wallpaper.thumb_path.empty()) {
    return 0;
  }
  if (auto it = textures_.find(wallpaper.thumb_path); it != textures_.end()) {
    return it->second;
  }
  try {
    vips::VImage image = vips::VImage::new_from_file(wallpaper.thumb_path.c_str());
    image = image.colourspace(VIPS_INTERPRETATION_sRGB);
    if (image.bands() == 3) {
      image = image.bandjoin(255);
    } else if (image.bands() > 4) {
      image = image.extract_band(0, vips::VImage::option()->set("n", 4));
    }
    size_t bytes = 0;
    void *memory = image.write_to_memory(&bytes);
    GLuint texture = 0;
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, image.width(), image.height(), 0, GL_RGBA,
                 GL_UNSIGNED_BYTE, memory);
    g_free(memory);
    textures_[wallpaper.thumb_path] = texture;
    return texture;
  } catch (const std::exception &err) {
    std::cerr << "texture warning: " << wallpaper.thumb_path << ": " << err.what() << '\n';
    return 0;
  }
}

void Renderer::draw_rect(float x, float y, float w, float h, float r, float g, float b, float a) {
  const GLfloat vertices[] = {
      ndc_x(x, width_),     ndc_y(y, height_),     0.0F, 0.0F,
      ndc_x(x + w, width_), ndc_y(y, height_),     1.0F, 0.0F,
      ndc_x(x, width_),     ndc_y(y + h, height_), 0.0F, 1.0F,
      ndc_x(x + w, width_), ndc_y(y + h, height_), 1.0F, 1.0F,
  };
  glUseProgram(program_);
  glUniform4f(color_loc_, r, g, b, a);
  glUniform1i(use_texture_loc_, 0);
  glVertexAttribPointer(pos_loc_, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(GLfloat), vertices);
  glVertexAttribPointer(uv_loc_, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(GLfloat), vertices + 2);
  glEnableVertexAttribArray(pos_loc_);
  glEnableVertexAttribArray(uv_loc_);
  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

void Renderer::draw_textured_quad(float x, float y, float w, float h, GLuint texture, float alpha) {
  if (texture == 0) {
    draw_rect(x, y, w, h, 0.10F, 0.12F, 0.15F, alpha);
    return;
  }
  const GLfloat vertices[] = {
      ndc_x(x, width_),     ndc_y(y, height_),     0.0F, 0.0F,
      ndc_x(x + w, width_), ndc_y(y, height_),     1.0F, 0.0F,
      ndc_x(x, width_),     ndc_y(y + h, height_), 0.0F, 1.0F,
      ndc_x(x + w, width_), ndc_y(y + h, height_), 1.0F, 1.0F,
  };
  glUseProgram(program_);
  glActiveTexture(GL_TEXTURE0);
  glBindTexture(GL_TEXTURE_2D, texture);
  glUniform4f(color_loc_, 1.0F, 1.0F, 1.0F, alpha);
  glUniform1i(use_texture_loc_, 1);
  glVertexAttribPointer(pos_loc_, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(GLfloat), vertices);
  glVertexAttribPointer(uv_loc_, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(GLfloat), vertices + 2);
  glEnableVertexAttribArray(pos_loc_);
  glEnableVertexAttribArray(uv_loc_);
  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

void Renderer::draw_polygon(const std::vector<Point> &points, float r, float g, float b, float a) {
  std::vector<GLfloat> vertices;
  vertices.reserve(points.size() * 4);
  for (const auto &point : points) {
    vertices.push_back(ndc_x(point.x, width_));
    vertices.push_back(ndc_y(point.y, height_));
    vertices.push_back(0.5F);
    vertices.push_back(0.5F);
  }
  glUseProgram(program_);
  glUniform4f(color_loc_, r, g, b, a);
  glUniform1i(use_texture_loc_, 0);
  glVertexAttribPointer(pos_loc_, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(GLfloat), vertices.data());
  glVertexAttribPointer(uv_loc_, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(GLfloat), vertices.data() + 2);
  glEnableVertexAttribArray(pos_loc_);
  glEnableVertexAttribArray(uv_loc_);
  glDrawArrays(GL_TRIANGLE_FAN, 0, static_cast<GLsizei>(points.size()));
}

void Renderer::draw_text(float x, float y, const std::string &text, float scale, float r, float g,
                         float b, float a) {
  float cursor = x;
  for (char raw : text) {
    const char c = static_cast<char>(std::toupper(static_cast<unsigned char>(raw)));
    const auto bits = glyph(c);
    for (int row = 0; row < 7; ++row) {
      for (int col = 0; col < 5; ++col) {
        if ((bits[row] & (1 << (4 - col))) != 0) {
          draw_rect(cursor + col * scale, y + row * scale, scale * 0.82F, scale * 0.82F, r, g, b, a);
        }
      }
    }
    cursor += scale * 6.0F;
    if (cursor > width_ - 20.0F) {
      return;
    }
  }
}

void Renderer::render(const std::vector<Wallpaper> &wallpapers, int selected, DisplayMode mode,
                      const std::string &query) {
  hit_regions_.clear();
  glClearColor(0.035F, 0.040F, 0.052F, 0.96F);
  glClear(GL_COLOR_BUFFER_BIT);
  draw_rect(0, 0, static_cast<float>(width_), 54, 0.06F, 0.07F, 0.09F, 0.92F);
  draw_text(22, 18, "VIBEWALL REZERO", 3.0F, 0.95F, 0.74F, 0.25F, 1.0F);
  draw_text(330, 18, "1 SLICE  2 GRID  3 HEX  / SEARCH  ENTER APPLY  ESC CLOSE", 2.2F,
            0.72F, 0.76F, 0.82F, 1.0F);
  if (!query.empty()) {
    draw_text(22, 44, "SEARCH:" + query, 2.0F, 0.55F, 0.85F, 1.0F, 1.0F);
  }

  if (wallpapers.empty()) {
    draw_text(width_ * 0.25F, height_ * 0.48F, "NO WALLPAPERS - RUN VIBEWALL SCAN", 3.0F,
              0.9F, 0.9F, 0.9F, 1.0F);
    return;
  }

  switch (mode) {
  case DisplayMode::Slice:
    render_slice(wallpapers, selected);
    break;
  case DisplayMode::Grid:
    render_grid(wallpapers, selected);
    break;
  case DisplayMode::Hex:
    render_hex(wallpapers, selected);
    break;
  }
}

void Renderer::render_grid(const std::vector<Wallpaper> &wallpapers, int selected) {
  const float margin = 36.0F;
  const float top = 82.0F;
  const float gap = 18.0F;
  const float cell_w = 210.0F;
  const float cell_h = 148.0F;
  const int cols = std::max(1, static_cast<int>((width_ - margin * 2 + gap) / (cell_w + gap)));
  const int selected_row = std::max(0, selected / cols);
  const int visible_rows = std::max(1, static_cast<int>((height_ - top) / (cell_h + gap)));
  const int start_row = std::max(0, selected_row - visible_rows / 2);
  const int start = start_row * cols;
  const int end = std::min<int>(wallpapers.size(), start + (visible_rows + 2) * cols);

  for (int i = start; i < end; ++i) {
    const int local = i - start;
    const int row = local / cols;
    const int col = local % cols;
    const float x = margin + col * (cell_w + gap);
    const float y = top + row * (cell_h + gap);
    const auto color = color_from_group(wallpapers[i].color_group);
    draw_rect(x - 4, y - 4, cell_w + 8, cell_h + 8, color[0], color[1], color[2],
              i == selected ? 0.95F : 0.22F);
    draw_textured_quad(x, y, cell_w, cell_h, texture_for(wallpapers[i]), 0.96F);
    draw_rect(x, y + cell_h - 26, cell_w, 26, 0.03F, 0.035F, 0.045F, 0.74F);
    draw_text(x + 8, y + cell_h - 18, wallpapers[i].name.substr(0, 22), 1.7F, 0.92F, 0.94F,
              0.98F, 1.0F);
    hit_regions_.push_back({i, {{x, y}, {x + cell_w, y}, {x + cell_w, y + cell_h}, {x, y + cell_h}}});
  }
}

void Renderer::render_slice(const std::vector<Wallpaper> &wallpapers, int selected) {
  const int count = static_cast<int>(wallpapers.size());
  const float center_x = width_ * 0.5F;
  const float center_y = height_ * 0.52F;
  for (int offset = -3; offset <= 3; ++offset) {
    int index = selected + offset;
    if (index < 0 || index >= count) {
      continue;
    }
    const float focus = offset == 0 ? 1.0F : 0.70F;
    const float w = (offset == 0 ? 360.0F : 240.0F);
    const float h = (offset == 0 ? 430.0F : 330.0F);
    const float x = center_x + offset * 185.0F - w * 0.5F;
    const float y = center_y - h * 0.5F + std::abs(offset) * 22.0F;
    const float skew = 48.0F;
    const auto color = color_from_group(wallpapers[index].color_group);
    const std::vector<Point> poly = {{x + skew, y}, {x + w, y}, {x + w - skew, y + h}, {x, y + h}};
    draw_polygon(poly, color[0], color[1], color[2], offset == 0 ? 0.58F : 0.28F);
    draw_textured_quad(x + 18, y + 18, w - 36, h - 58, texture_for(wallpapers[index]), focus);
    draw_text(x + 28, y + h - 30, wallpapers[index].name.substr(0, 24), 2.1F, 0.95F, 0.95F,
              0.95F, 1.0F);
    hit_regions_.push_back({index, poly});
  }
}

void Renderer::render_hex(const std::vector<Wallpaper> &wallpapers, int selected) {
  const float r = 86.0F;
  const float step_x = r * 1.55F;
  const float step_y = r * 1.34F;
  const int cols = std::max(1, static_cast<int>(width_ / step_x));
  const int selected_row = std::max(0, selected / cols);
  const int visible_rows = std::max(1, static_cast<int>((height_ - 90) / step_y));
  const int start_row = std::max(0, selected_row - visible_rows / 2);
  const int start = start_row * cols;
  const int end = std::min<int>(wallpapers.size(), start + (visible_rows + 2) * cols);

  for (int i = start; i < end; ++i) {
    const int local = i - start;
    const int row = local / cols;
    const int col = local % cols;
    const float cx = 72.0F + col * step_x + (row % 2 == 0 ? 0.0F : step_x * 0.5F);
    const float cy = 122.0F + row * step_y;
    std::vector<Point> poly;
    for (int k = 0; k < 6; ++k) {
      const float angle = static_cast<float>(M_PI / 6.0 + k * M_PI / 3.0);
      poly.push_back({cx + std::cos(angle) * r, cy + std::sin(angle) * r});
    }
    const auto color = color_from_group(wallpapers[i].color_group);
    draw_polygon(poly, color[0], color[1], color[2], i == selected ? 0.92F : 0.42F);
    draw_textured_quad(cx - r * 0.62F, cy - r * 0.46F, r * 1.24F, r * 0.92F,
                       texture_for(wallpapers[i]), 0.90F);
    draw_text(cx - r * 0.55F, cy + r * 0.48F, wallpapers[i].name.substr(0, 13), 1.6F, 0.96F,
              0.96F, 0.96F, 1.0F);
    hit_regions_.push_back({i, poly});
  }
}

int Renderer::hit_test(float x, float y) const {
  for (const auto &region : hit_regions_) {
    if (region.polygon.size() >= 3 && point_in_polygon(x, y, region.polygon)) {
      return region.index;
    }
  }
  return -1;
}

} // namespace vibewall::picker
