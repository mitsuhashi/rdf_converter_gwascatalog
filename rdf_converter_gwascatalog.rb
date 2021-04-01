#!/usr/bin/env ruby

require 'csv'


def prefixes
  print "@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .\n"
  print "@prefix terms: <http://med2rdf.org/gwascatalog/terms/> .\n"
  print "@prefix gwas: <http://rdf.ebi.ac.uk/terms/gwas/> .\n"
  print "@prefix oban: <http://purl.org/oban/> .\n"
  print "@prefix owl: <http://www.w3.org/2002/07/owl#> .\n"
  print "@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .\n"
  print "@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .\n"
  print "@prefix ro: <http://www.obofoundry.org/ro/ro.owl#> .\n"
  print "@prefix study: <http://www.ebi.ac.uk/gwas/studies/> .\n"
  print "@prefix dct: <http://purl.org/dc/terms/> .\n"
  print "@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .\n"
  print "@prefix pubmed: <http://rdf.ncbi.nlm.nih.gov/pubmed/> .\n"
  print "\n"
end


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


#DATE ADDED TO CATALOG	PUBMEDID	FIRST AUTHOR	DATE	JOURNAL	LINK	STUDY	DISEASE/TRAIT	INITIAL SAMPLE SIZE	REPLICATION SAMPLE SIZE	PLATFORM [SNPS PASSING QC]	ASSOCIATION COUNT	MAPPED_TRAIT	MAPPED_TRAIT_URISTUDY ACCESSION	GENOTYPING TECHNOLOGY
