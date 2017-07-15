require 'sinatra' #calls the sinatra framework
require 'data_mapper' #calls the data_mapper framework. This is used for the database and for the create, add, delete, remove functionalities

DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/wiki.db")

class User #set a class with the specified properties
	include DataMapper::Resource
	property :id, Serial
	property :username, Text, :required => true
	property :password, Text, :required => true
	property :date_joined, DateTime
	property :edit, Boolean, :required =>true, :default =>false
end

DataMapper.finalize.auto_upgrade!

	
$myinfo = "Koce Mil"
@info= ""

def readFile(wiki) #define the method for reading a file and placing an input inside it
	info = ""
	file=File.open(wiki)
	file.each do |line|
		info = info + line #this adds to the text file without overwriting the original content
	end
	file.close #we always close the file so we do not leave memory in use
	$myinfo = info
end

get '/' do #this is the home page and contains information about the functionality of the words and characters counters, u recognize it with GET
	info = ""
	len = info.length
	len1 = len
	readFile("wiki.txt") #use the method for reading a file which was specified earlier
	@info = info + "" + $myinfo
	len = @info.length
	len2 = len - 1
	len3 = len2 - len1
	@words = len3.to_s
	
		
	file = File.open("wiki.txt")
	file.each do |line|
	  info = info + line
	end

	file.close
	@wiki = info #This piece of code counts the words

	sentence = @wiki
	splits = sentence.split(" ")
	@words2 = splits.length.to_i


	erb :home #calls the home view, which is located in the views project folder
end


get '/about' do # get specifies which page will be developed
	erb :about
end

get '/create' do
	erb :create
end


get '/edit' do
	protected! #if the user does not have access control rights he will not be able to access the page
	info = ""
	file = File.open("wiki.txt")
	file.each do |line|
		info = info + line
	end
	file.close
	@info = info
	erb :edit
end







put '/edit' do
	info = "#{params[:message]}" #This is the update button working, it updates the code on the wiki.txt file
	@info = info
	file= File.open("wiki.txt", "w")
	file.puts @info
	file.close          
	
	
	file = File.open("login_record.txt", "a") #open the login_record file
	username = $credentials[0]
	timenow = Time.now.asctime
	message = "#{username} edited the text at #{timenow} with the changed text being: #{params[:message]}"#This is the message
	file.puts message #we write the message down
	file.close
	redirect '/edit'
	
end




get '/backup' do #This is how we save the current information onto a backup file
	file= File.open("wiki.txt", "r")
	@data = file.read
	file.close
	file = File.open("backup.txt", "w")
	file.puts @data
	file.close
	redirect '/edit'
end

get '/reset' do #This is how we reset any changes made and bring the text back to its original content
	
	file = File.open("default.txt")
	@data = file.read
	file.close
	file= File.open("wiki.txt", "w")
	file.puts @data
	file.close
	
	redirect '/edit'
end

get '/restore' do # This takes the text saved from the backup and restores it on the webpage
	file = File.open("backup.txt", "r")
	@data = file.read
	file.close
	file= File.open("wiki.txt", "w")
	file.puts @data
	file.close
	
	redirect '/edit'
end


get '/login' do
	erb :login
end

post '/login' do #how the log in is accomplished 
	$credentials = [params[:username],params[:password]] #specify which properties the credentials will occupy 
	@Users = User.first(:username => $credentials[0]) #looks for a username
	if @Users
		if @Users.password == $credentials[1]
			file = File.open("login_record.txt", "a")
			username = $credentials[0]
			timenow = Time.now.asctime
			message = "#{username} logged in at #{timenow}"
			file.puts message
			file.close
			redirect '/'
		else
			$credentials =['','']
			redirect '/wrongaccount' #if the credentials are not identical to the ones specified on the previous statement
		end
	else
		$credentials = ['','']
		redirect '/wrongaccount'
	end
	
	
end



get '/video' do
	erb :video
end

get '/quiz' do
	erb :quiz
end


get '/wrongaccount' do
	erb :wrongaccount
end

get '/user/:uzer' do #identifies and authorizes the user or denies access
	@Userz = User.first(:username =>params[:uzer]) 
	if @Userz !=nil
		erb :profile
	else	
		redirect '/noaccount'
	end
end

get '/createaccount' do
	erb :createaccount
end

get '/logout' do
		$credentials = ['', '']
		redirect '/'
	end

put '/user/:uzer' do
	n = User.first(:username => params[:uzer])
	n.edit = params[:edit]? 1:0 
	n.save
	redirect '/' 
end

get '/admincontrols' do
	protected! 
	@list2 = User.all :order => :id.desc
	erb :admincontrols
end

get '/user/delete/:uzer' do
	protected!
	n = User.first(:username => params[:uzer])
	if n.username == "Admin"
		erb :denied
	else
		n.destroy
		@list2 = User.all :order => :id.desc
		erb :admincontrols
	end
end

post '/createaccount' do
	n = User.new
	n.username = params[:username]
	n.password = params[:password]
	n.date_joined = Time.now
	if n.username == "Admin" and n.password == "Password"
		n.edit = true 
	end
	n.save
	redirect '/'
end
	

get '/notfound' do
	erb :notfound
end

get '/noaccount' do
	erb :noaccount
end

get '/denied' do
erb :denied
end


not_found do
	status 404
	redirect '/notfound'
end

helpers do #this helps access control featues so unauthorized actors cannot access the specified
	def protected!
		if authorized?
			return
		end
		redirect '/denied' 
	end
	
	def authorized? 
		if $credentials != nil
			@Userz = User.first(:username => $credentials[0])
			if @Userz
				if @Userz.edit ==true
					return true
				else
					return false
				end
			else
				return false 
			end
		end
	end
end
				