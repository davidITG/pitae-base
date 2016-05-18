require 'mechanize'
require 'pry-byebug'

url = 'http://www.skolverket.se/laroplaner-amnen-och-kurser/gymnasieutbildning/gymnasieskola/sok-amnen-kurser-och-program/search.htm?alphaSearchString=&searchType=FREETEXT&searchRange=COURSE&subjectCategory=&searchString='
subject_url_regex = /\S+subjectCode=(\w{3})&lang\S+/

agent = Mechanize.new

results_page = agent.get(url)

subject_links = results_page.links_with(href: subject_url_regex)

subjects = []

subject_links.each do |subject_link|
	
	subject_name = subject_link.text
	puts "Indexing #{subject_name}"
	subject_code = subject_link.href.match(subject_url_regex)[1]
	
	subject_page = subject_link.click

	course_articles = subject_page.search('section[class="courses-wrapper"] article')

	courses = []
	course_articles.each do |course_article|
		name, credits = course_article.search('a[href="#"]').text.scan(/^(.+), (\d{2,3}).+$/).flatten
		puts "	course: #{name}"
		code = course_article.search('div[class="course-details"] > p > strong').text.scan(/^Kurskod: (.+)$/).flatten[0]
		central_content = course_articles.search('h4 + p + ul').children.children.map {|ct| ct.text}
		e_level_knowledge_requirements = course_article.search('h4:contains("Betyget E") ~ p').to_html
		c_level_knowledge_requirements = course_article.search('h4:contains("Betyget C") ~ p').to_html
		a_level_knowledge_requirements = course_article.search('h4:contains("Betyget A") ~ p').to_html
		courses << {name: name, 
					credits: credits, 
					code: code, 
					central_content: central_content, 
					e_kn_req: e_level_knowledge_requirements,
					c_kn_req: c_level_knowledge_requirements,
					a_kn_req: a_level_knowledge_requirements}

	end
	subjects << {name: subject_name, code: subject_code, courses: courses}
end

File.open('data.yaml', 'w') { |f| f.write subjects.to_yaml }




