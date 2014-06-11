#!/bin/ruby
# -*- coding: utf-8 -*-

# CSV形式のセッションの詳細情報から、
# Front matter付きのセッションページを生成

require 'csv'
require 'yaml'
require './_scripts/papercache.rb'
require './_scripts/sessioncache.rb'
require './_scripts/personcache.rb'

session_folder = "_posts/generated"

papercache = PaperCache.new
sessioncache = SessionCache.new
personcache = PersonCache.new(papercache)

while sessioncache.hasNext?
  session = sessioncache.next

  # セッション情報
  session_file_name = sprintf "%d-%02d-%02d-session-%s.html", session[:year], session[:month], session[:day], session[:id]
  puts "generating " + session_file_name
  session_file_path = session_folder + "/" + session_file_name

  front = {"category" => "session", "layout" => "session"}
  front["title"] = session[:title]
  front["pageid"] = session[:id]
  if /^\d(?<roomid>.+)/ =~ session[:id] then
    front["tags"] = "normal"
    front["roomid"] = roomid
  else
    front["tags"] = session[:id]
    front["roomid"] = session[:id]
  end
  # 時間
  front["start"] = sprintf "%d-%02d-%02d %s:00", session[:year], session[:month], session[:day], session[:start]
  front["end"] = sprintf "%d-%02d-%02d %s:00", session[:year], session[:month], session[:day], session[:end]
  # 部屋
  front["location"] = session[:location]
  # 座長
  if session[:chairname] then
    front["chair"] = session[:chairname] + " (" + session[:chairorg] + ")";
    if personcache.name[session[:chairname]] then
      person = personcache.name[session[:chairname]]
      front["chairpid"] = person.id
    end
  end
  # 論文
  paperlist = []
  session[:paper].each do |paper|
    fpaper = {"title" => paper[:title], "psid" => paper[:psid],
      "paperid" => paper[:id]}
    pid = paper[:id]
    if papercache.number[pid] then
      paperitem = papercache.number[pid]
      puts "not found " + pid unless paperitem
      if paperitem.right? then
        fpaper["abstract"] = paperitem.abstract
      end
    end
    authorlist = []
    paper[:author].each do |author|
      aitem = {"name" => author[:name], "org" => author[:org]}
      aitem["presenter"] = true if author[:presenter]
      person = personcache.name[author[:name]]
      if person then
        aitem["pid"] = person.id
      end
      authorlist << aitem
    end
    fpaper["author"] = authorlist
    paperlist << fpaper
  end
  front["paper"] = paperlist
  File.open(session_file_path, "wb") do |f|
    f.write YAML.dump(front)
    f.write "---\n"
  end #file
#  puts row
end
