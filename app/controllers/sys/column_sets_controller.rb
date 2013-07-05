class Sys::ColumnSetsController < ApplicationController
  # GET /sys/column_sets
  # GET /sys/column_sets.json
  def index
    @sys_column_sets = Sys::ColumnSet.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @sys_column_sets }
    end
  end

  # GET /sys/column_sets/1
  # GET /sys/column_sets/1.json
  def show
    @sys_column_set = Sys::ColumnSet.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @sys_column_set }
    end
  end

  # GET /sys/column_sets/new
  # GET /sys/column_sets/new.json
  def new
    @sys_column_set = Sys::ColumnSet.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @sys_column_set }
    end
  end

  # GET /sys/column_sets/1/edit
  def edit
    @sys_column_set = Sys::ColumnSet.find(params[:id])
  end

  # POST /sys/column_sets
  # POST /sys/column_sets.json
  def create
    @sys_column_set = Sys::ColumnSet.new(params[:sys_column_set])

    respond_to do |format|
      if @sys_column_set.save
        format.html { redirect_to @sys_column_set, notice: 'Column set was successfully created.' }
        format.json { render json: @sys_column_set, status: :created, location: @sys_column_set }
      else
        format.html { render action: "new" }
        format.json { render json: @sys_column_set.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /sys/column_sets/1
  # PUT /sys/column_sets/1.json
  def update
    @sys_column_set = Sys::ColumnSet.find(params[:id])

    respond_to do |format|
      if @sys_column_set.update_attributes(params[:sys_column_set])
        format.html { redirect_to @sys_column_set, notice: 'Column set was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @sys_column_set.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /sys/column_sets/1
  # DELETE /sys/column_sets/1.json
  def destroy
    @sys_column_set = Sys::ColumnSet.find(params[:id])
    @sys_column_set.destroy

    respond_to do |format|
      format.html { redirect_to sys_column_sets_url }
      format.json { head :no_content }
    end
  end
end
