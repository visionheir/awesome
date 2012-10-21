class AliensController < ApplicationController
  # GET /aliens
  # GET /aliens.json
  def index
    @aliens = Alien.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @aliens }
    end
  end

  # GET /aliens/1
  # GET /aliens/1.json
  def show
    @alien = Alien.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @alien }
    end
  end

  # GET /aliens/new
  # GET /aliens/new.json
  def new
    @alien = Alien.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @alien }
    end
  end

  # GET /aliens/1/edit
  def edit
    @alien = Alien.find(params[:id])
  end

  # POST /aliens
  # POST /aliens.json
  def create
    @alien = Alien.new(params[:alien])

    respond_to do |format|
      if @alien.save
        format.html { redirect_to @alien, notice: 'Alien was successfully created.' }
        format.json { render json: @alien, status: :created, location: @alien }
      else
        format.html { render action: "new" }
        format.json { render json: @alien.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /aliens/1
  # PUT /aliens/1.json
  def update
    @alien = Alien.find(params[:id])

    respond_to do |format|
      if @alien.update_attributes(params[:alien])
        format.html { redirect_to @alien, notice: 'Alien was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @alien.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /aliens/1
  # DELETE /aliens/1.json
  def destroy
    @alien = Alien.find(params[:id])
    @alien.destroy

    respond_to do |format|
      format.html { redirect_to aliens_url }
      format.json { head :no_content }
    end
  end
end
