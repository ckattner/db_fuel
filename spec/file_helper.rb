# frozen_string_literal: true

#
# Copyright (c) 2020-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

def read_yaml_file(*filename)
  YAML.safe_load(read_file(*filename))
end

def read_file(*filename)
  IO.read(File.join(*filename))
end
