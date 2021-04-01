#!/usr/bin/env ruby

require 'csv'
require 'optparse'

module GWASCatalog

  Prefixes = {
    "rdf" =>    "<http://www.w3.org/1999/02/22-rdf-syntax-ns#>",
    "terms" =>  "<http://med2rdf.org/gwascatalog/terms/>",
    "gwas" =>   "<http://rdf.ebi.ac.uk/terms/gwas/>",
    "oban" =>   "<http://purl.org/oban/>",
    "owl" =>    "<http://www.w3.org/2002/07/owl#>",
    "xsd" =>    "<http://www.w3.org/2001/XMLSchema#>",
    "rdfs" =>   "<http://www.w3.org/2000/01/rdf-schema#>",
    "ro" =>     "<http://www.obofoundry.org/ro/ro.owl#>",
    "study" =>  "<http://www.ebi.ac.uk/gwas/studies/>",
    "dct" =>    "<http://purl.org/dc/terms/>",
    "pubmed" => "<http://rdf.ncbi.nlm.nih.gov/pubmed/>"
  }

  def prefixes
    Prefixes.each do |pfx, uri|
      print "@prefix #{pfx}: #{uri} .\n"
    end
    puts "\n"
  end
  module_function :prefixes

  class Study

    def self.rdf(file, prefixes = false)
      File.open(file) do |f|
        keys = parse_header(f.gets)
        GWASCatalog.prefixes if $prefixes
        while line = f.gets
          ary = line.chomp.split("\t")
          study = [keys, ary].transpose.to_h
          puts turtle(study)
        end
      end
    end

    def self.parse_header(header)
      header.chomp
            .split("\t") 
            .map{|e| e.downcase.gsub(/[\-\s\/]/, '_')
            .gsub(/[\[\]]/, '')
            .to_sym}
    end

    def self.turtle(h)
      turtle = <<~"TURTLE"
        study:#{h[:study_accession]} a gwas:Study ;
          dct:identifier "#{h[:study_accession]}" ;
          dct:date "#{h[:date_added_to_catalog]}"^^xsd:date ;
          dct:references pubmed:#{h[:pubmedid]} ;
          gwas:has_pubmed_id "#{h[:pubmedid]}"^^xsd:string ;
          dct:description "#{h[:disease_trait]}"@en ;
          terms:initial_sample_size "#{h[:initial_sample_size]}"@en ;
          terms:replication_sample_size "#{h[:replication_sample_size]}"@en ;
          terms:platform_snps_passing_qc "#{h[:platform_snps_passing_qc]}" ;
          terms:association_count #{h[:association_count]} ;
          terms:mapped_trait #{h[:mapped_trait_uri].size == 0 ? "\"\"" : h[:mapped_trait_uri].split(", ").map{|e| "<#{e}>"}.join(', ')} ;
          terms:genotyping_technology "#{h[:genotyping_technology]}" .

      TURTLE
    end

  end

  class Association

  end
 
end

def help
  print "Usage: > ruby rdf_converter_gwascatalog.rb [options] <file>\n"
end


params = ARGV.getopts('hps:a:', 'help', 'prefixes', 'study:', 'association:')

if params["help"] || params["h"]
  help
  exit
end

$prefixes = true                                    if params["prefixes"]
$prefixes = true                                    if params["p"]
GWASCatalog::Study.rdf(params["study"])             if params["study"]
GWASCatalog::Study.rdf(params["s"])                 if params["s"]
GWASCatalog::Association.rdf(params["association"]) if params["association"]
GWASCatalog::Association.rdf(params["a"])           if params["a"]


=begin

def turtle(h)

  turtle = <<"TURTLE"
study:#{h[:study_accession]} a gwas:Study ;
  dct:identifier "#{h[:study_accession]}" ;
  dct:date "#{h[:date_added_to_catalog]}"^^xsd:date ;
  dct:references pubmed:#{h[:pubmedid]} ;
  gwas:has_pubmed_id "#{h[:pubmedid]}"^^xsd:string ;
  dct:description "#{h[:disease_trait]}"@en ;
  terms:initial_sample_size "#{h[:initial_sample_size]}"@en ;
  terms:replication_sample_size "#{h[:replication_sample_size]}"@en ;
  terms:platform_snps_passing_qc "#{h[:platform_snps_passing_qc]}" ;
  terms:association_count #{h[:association_count]} ;
  terms:mapped_trait #{h[:mapped_trait_uri].size == 0 ? "\"\"" : h[:mapped_trait_uri].split(", ").map{|e| "<#{e}>"}.join(', ')} ;
  terms:genotyping_technology "#{h[:genotyping_technology]}" .

TURTLE

end

file = open(ARGV.shift)

header = file.gets
keys = header.chomp.split("\t").map{|e| e.downcase.gsub(/[\-\s\/]/, '_').gsub(/[\[\]]/, '').to_sym}

prefixes

while line = file.gets
  ary = line.chomp.split("\t")
  study = [keys, ary].transpose.to_h
#  p study
  puts turtle(study)
end

=end
