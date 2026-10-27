require "rails_helper"

RSpec.describe CsvImport do
  # Records each row's name and fails rows named "bad", so the shared reading can be tested on its own.
  let(:importer_class) do
    Class.new(described_class) do
      const_set(:REQUIRED_HEADERS, %w[name zone].freeze)
      attr_reader :seen

      def import_row(row)
        (@seen ||= []) << value(row, "name")
        require_values!(row, "name", "zone")
        raise CsvImport::RowError, "mala" if value(row, "name") == "bad"

        value(row, "zone") == "update" ? :updated : :created
      end
    end
  end

  def upload(content)
    StringIO.new(content.b)
  end

  def import(content)
    importer = importer_class.new(upload(content))
    [importer.call, importer]
  end

  it "matches headers ignoring case, spaces and column order" do
    result, importer = import(" Zone ,NAME\nBosa,Tienda\n")

    expect(result.created).to eq(1)
    expect(importer.seen).to eq(["Tienda"])
  end

  it "counts created and updated rows" do
    result, = import("name,zone\nA,Bosa\nB,update\n")

    expect([result.created, result.updated]).to eq([1, 1])
  end

  it "reports failed rows by file line, counting the header and blank lines, and keeps going" do
    result, = import("name,zone\nA,Bosa\n\nbad,Bosa\n,Bosa\nB,Bosa\n,,\n")

    expect(result.created).to eq(2)
    expect(result.failures).to eq([[4, "mala"], [5, "falta name"]])
  end

  it "strips a UTF-8 byte-order mark" do
    _, importer = import("﻿name,zone\nTienda San José,Bosa\n")

    expect(importer.seen).to eq(["Tienda San José"])
  end

  it "falls back to Windows-1252 when the file is not valid UTF-8" do
    importer = importer_class.new(StringIO.new("name,zone\nTienda San Jos\xE9,Bosa\n".b))
    importer.call

    expect(importer.seen).to eq(["Tienda San José"])
  end

  it "rejects a file missing a required column, naming it" do
    expect { import("name,address\nA,Calle 1\n") }
      .to raise_error(CsvImport::InvalidFile, "Al archivo le faltan las columnas: zone.")
  end

  it "rejects a malformed file" do
    expect { import("name,zone\n\"A,Bosa\n") }.to raise_error(CsvImport::InvalidFile, /no es un CSV válido/)
  end

  it "rejects a missing file" do
    expect { importer_class.new(nil).call }
      .to raise_error(CsvImport::InvalidFile, "Selecciona un archivo CSV para cargar.")
  end

  it "rejects a file over 2 MB" do
    big = upload("name,zone\n#{"A,Bosa\n" * 400_000}")

    expect { importer_class.new(big).call }.to raise_error(CsvImport::InvalidFile, /2 MB/)
  end

  it "accepts a file with only the header" do
    result, = import("name,zone\n")

    expect([result.created, result.failures]).to eq([0, []])
  end

  describe CsvImport::Result do
    it "lists at most 20 failures and says how many more there were" do
      result = CsvImport::Result.new(0, 0, (2..26).map { |line| [line, "falta name"] })

      lines = result.failure_lines
      expect(lines.size).to eq(21)
      expect(lines.first).to eq("Fila 2: falta name")
      expect(lines.last).to eq("Y 5 filas más con errores.")
    end
  end
end
