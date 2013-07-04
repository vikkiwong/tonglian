class ColumnSetsController < ApplicationController
  # GET /column_sets
  # GET /column_sets.json
  def index
    @column_sets = ColumnSet.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @column_sets }
    end
  end

  # GET /column_sets/1
  # GET /column_sets/1.json
  def show
    @column_set = ColumnSet.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @column_set }
    end
  end

  # GET /column_sets/new
  # GET /column_sets/new.json
  def new
    @column_set = ColumnSet.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @column_set }
    end
  end

  # GET /column_sets/1/edit
  def edit
    @column_set = ColumnSet.find(params[:id])
  end

  # POST /column_sets
  # POST /column_sets.json
  def create
    @column_set = ColumnSet.new(params[:column_set])

    respond_to do |format|
      if @column_set.save
        format.html { redirect_to @column_set, notice: 'Column set was successfully created.' }
        format.json { render json: @column_set, status: :created, location: @column_set }
      else
        format.html { render action: "new" }
        format.json { render json: @column_set.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /column_sets/1
  # PUT /column_sets/1.json
  def update
    @column_set = ColumnSet.find(params[:id])

    respond_to do |format|
      if @column_set.update_attributes(params[:column_set])
        format.html { redirect_to @column_set, notice: 'Column set was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @column_set.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /column_sets/1
  # DELETE /column_sets/1.json
  def destroy
    @column_set = ColumnSet.find(params[:id])
    @column_set.destroy

    respond_to do |format|
      format.html { redirect_to column_sets_url }
      format.json { head :no_content }
    end
  end
end
