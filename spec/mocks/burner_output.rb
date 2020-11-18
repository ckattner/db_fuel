# frozen_string_literal: true

#
# Copyright (c) 2020-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

# Plugs into Burner::Output to intercept emitted standard output from Burner.
class StringSummary
  def initialize
    @io = StringIO.new
  end

  def puts(msg)
    tap { io.write("#{msg}\n") }
  end

  def read
    io.rewind
    io.read
  end

  private

  attr_reader :io
end

def make_burner_output
  Burner::Output.new(outs: [StringSummary.new])
end
